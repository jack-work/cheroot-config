package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"slices"
	"strings"
)

const (
	exitClean = 0
	exitDrift = 1
	exitUsage = 2
)

var (
	exactFormID = regexp.MustCompile(`^@([0-9a-f]{8}|[0-9a-f]{32})$`)
	callerEnv   = []string{"FIGARO_ARIA", "FIGARO_TROUPE", "FIGARO_CALLER"}
)

type manifest struct {
	Figaro string `json:"figaro"`
	Roles  []role `json:"roles"`
}

type role struct {
	Name    string   `json:"name"`
	Form    string   `json:"form"`
	Outfits []string `json:"outfits"`
	Managed []string `json:"managed"`
}

type result struct {
	Role     string   `json:"role"`
	Form     string   `json:"form"`
	Outcome  string   `json:"outcome"`
	Outfits  []string `json:"outfits"`
	Version  uint64   `json:"version,omitempty"`
	Set      []string `json:"set,omitempty"`
	Remove   []string `json:"remove,omitempty"`
	Unseated bool     `json:"unseated,omitempty"`
	Error    string   `json:"error,omitempty"`
}

func (r result) drifts() bool { return len(r.Set)+len(r.Remove) > 0 }

func main() { os.Exit(run(os.Args[1:], os.Stdout, os.Stderr)) }

func run(args []string, stdout, stderr io.Writer) int {
	fs := flag.NewFlagSet("figaro-apply", flag.ContinueOnError)
	fs.SetOutput(stderr)
	fs.Usage = func() {
		fmt.Fprintln(stderr, "Usage: figaro-apply [--check] [-j] [--manifest <roles.json>]")
		fmt.Fprintln(stderr, "\nApply each declared role's outfit to its form. Exit 0 clean, 1 drift or error, 2 usage.")
		fmt.Fprintln(stderr)
		fs.PrintDefaults()
	}
	check := fs.Bool("check", false, "print the plan and change nothing; exit 1 if any role drifts")
	asJSON := fs.Bool("j", false, "print one JSON object per role")
	path := fs.String("manifest", defaultManifest(), "role manifest written by the charter")
	if err := fs.Parse(args); err != nil {
		if errors.Is(err, flag.ErrHelp) {
			return exitClean
		}
		return exitUsage
	}
	if fs.NArg() > 0 {
		fmt.Fprintf(stderr, "figaro-apply: unexpected argument %q\n", fs.Arg(0))
		fs.Usage()
		return exitUsage
	}
	m, err := loadManifest(*path)
	if err != nil {
		fmt.Fprintln(stderr, "figaro-apply:", err)
		return exitDrift
	}
	bin := m.Figaro
	if bin == "" {
		bin = "figaro"
	}
	enc := json.NewEncoder(stdout)
	failed, drifted := 0, 0
	for _, r := range m.Roles {
		res := apply(bin, r, *check)
		switch {
		case res.Error != "":
			failed++
		case *check && res.drifts():
			drifted++
		}
		if *asJSON {
			enc.Encode(res)
		} else {
			printResult(stdout, res)
		}
	}
	switch {
	case failed > 0:
		fmt.Fprintf(stderr, "figaro-apply: %d of %d roles failed\n", failed, len(m.Roles))
	case drifted > 0:
		fmt.Fprintf(stderr, "figaro-apply: %d of %d roles drift; run without --check to apply\n", drifted, len(m.Roles))
	default:
		return exitClean
	}
	return exitDrift
}

func defaultManifest() string {
	dir, err := os.UserConfigDir()
	if err != nil {
		return ""
	}
	return filepath.Join(dir, "figaro", "roles.json")
}

func loadManifest(path string) (manifest, error) {
	var m manifest
	raw, err := os.ReadFile(path)
	if err != nil {
		return m, fmt.Errorf("manifest: %w", err)
	}
	dec := json.NewDecoder(bytes.NewReader(raw))
	dec.DisallowUnknownFields()
	if err := dec.Decode(&m); err != nil {
		return m, fmt.Errorf("manifest %s: %w", path, err)
	}
	if len(m.Roles) == 0 {
		return m, fmt.Errorf("manifest %s: no roles declared", path)
	}
	names, forms := map[string]bool{}, map[string]string{}
	for i, r := range m.Roles {
		if r.Name == "" {
			return m, fmt.Errorf("manifest %s: role %d has no name", path, i)
		}
		if names[r.Name] {
			return m, fmt.Errorf("manifest %s: role %s declared twice", path, r.Name)
		}
		names[r.Name] = true
		if !exactFormID.MatchString(r.Form) {
			return m, fmt.Errorf("manifest %s: %s: form %q is not an exact form id", path, r.Name, r.Form)
		}
		if other, dup := forms[r.Form]; dup {
			return m, fmt.Errorf("manifest %s: %s and %s both declare %s", path, other, r.Name, r.Form)
		}
		forms[r.Form] = r.Name
		if err := checkList("outfits", r.Outfits); err != nil {
			return m, fmt.Errorf("manifest %s: %s: %w", path, r.Name, err)
		}
		if err := checkList("managed", r.Managed); err != nil {
			return m, fmt.Errorf("manifest %s: %s: %w", path, r.Name, err)
		}
	}
	return m, nil
}

func checkList(field string, items []string) error {
	if len(items) == 0 {
		return fmt.Errorf("%s is empty", field)
	}
	for _, it := range items {
		if it == "" || strings.ContainsAny(it, ", \t\n") {
			return fmt.Errorf("%s entry %q is blank or holds a separator", field, it)
		}
	}
	return nil
}

func formApplyArgs(r role, check bool) []string {
	args := []string{"form", "apply", "--id", r.Form, "-O", strings.Join(r.Outfits, ","), "--managed", strings.Join(r.Managed, ","), "-j"}
	if check {
		args = append(args, "--check")
	}
	return args
}

func withoutCallerEnv(env []string) []string {
	kept := make([]string, 0, len(env))
	for _, kv := range env {
		key, _, _ := strings.Cut(kv, "=")
		if !slices.Contains(callerEnv, key) {
			kept = append(kept, kv)
		}
	}
	return kept
}

func apply(bin string, r role, check bool) result {
	res := result{Role: r.Name, Form: r.Form, Outcome: "error", Outfits: r.Outfits}
	cmd := exec.Command(bin, formApplyArgs(r, check)...)
	cmd.Env = withoutCallerEnv(os.Environ())
	var stderr bytes.Buffer
	cmd.Stderr = &stderr
	out, err := cmd.Output()
	if err != nil {
		res.Error = firstNonEmpty(stderr.String(), string(out), err.Error())
		return res
	}
	var reply struct {
		Version  uint64   `json:"version"`
		Outcome  string   `json:"outcome"`
		Set      []string `json:"set"`
		Remove   []string `json:"remove"`
		Unseated bool     `json:"unseated"`
	}
	if err := json.Unmarshal(out, &reply); err != nil || reply.Outcome == "" {
		res.Error = "unreadable reply from figaro form apply: " + firstNonEmpty(string(out), "empty")
		return res
	}
	res.Outcome, res.Version, res.Set, res.Remove, res.Unseated = reply.Outcome, reply.Version, reply.Set, reply.Remove, reply.Unseated
	return res
}

func firstNonEmpty(texts ...string) string {
	for _, t := range texts {
		if t = strings.TrimSpace(t); t != "" {
			return t
		}
	}
	return ""
}

func printResult(w io.Writer, r result) {
	unseated := ""
	if r.Unseated {
		unseated = ", unseated"
	}
	fmt.Fprintf(w, "%s %s: %s%s\n", r.Role, r.Form, r.Outcome, unseated)
	if r.Error != "" {
		fmt.Fprintf(w, "  error: %s\n", r.Error)
	}
	if len(r.Set) > 0 {
		fmt.Fprintf(w, "  set: %s\n", strings.Join(r.Set, ", "))
	}
	if len(r.Remove) > 0 {
		fmt.Fprintf(w, "  remove: %s\n", strings.Join(r.Remove, ", "))
	}
}
