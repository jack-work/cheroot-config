package main

import (
	"bufio"
	"bytes"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"slices"
	"strings"
	"testing"
)

const (
	formA = "@4f6f262b4f6f262b4f6f262b4f6f262b"
	formB = "@2b4fe37f"
)

type fakeRole struct {
	Set    []string `json:"set,omitempty"`
	Remove []string `json:"remove,omitempty"`
	Fail   string   `json:"fail,omitempty"`
	Reply  string   `json:"reply,omitempty"`
}

type fakeCall struct {
	Args []string          `json:"args"`
	Env  map[string]string `json:"env"`
}

var watchedEnv = []string{"FIGARO_ARIA", "FIGARO_TROUPE", "FIGARO_CALLER", "FIGARO_RUNTIME_DIR"}

func TestMain(m *testing.M) {
	if log := os.Getenv("FAKE_FIGARO_LOG"); log != "" && filepath.Base(os.Args[0]) == "figaro" {
		os.Exit(fakeFigaro(log))
	}
	os.Exit(m.Run())
}

func fakeFigaro(log string) int {
	call := fakeCall{Args: os.Args[1:], Env: map[string]string{}}
	for _, k := range watchedEnv {
		if v, ok := os.LookupEnv(k); ok {
			call.Env[k] = v
		}
	}
	line, _ := json.Marshal(call)
	f, err := os.OpenFile(log, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o600)
	if err != nil {
		return 3
	}
	fmt.Fprintf(f, "%s\n", line)
	f.Close()
	plan := map[string]fakeRole{}
	json.Unmarshal([]byte(os.Getenv("FAKE_FIGARO_PLAN")), &plan)
	i := slices.Index(call.Args, "--id")
	if i < 0 || i+1 >= len(call.Args) {
		fmt.Fprintln(os.Stderr, "fake figaro: no --id")
		return 2
	}
	id := call.Args[i+1]
	want := plan[id]
	switch {
	case want.Fail != "":
		fmt.Fprintln(os.Stderr, want.Fail)
		return 1
	case want.Reply != "":
		fmt.Print(want.Reply)
		return 0
	}
	outcome := "unchanged"
	if len(want.Set)+len(want.Remove) > 0 {
		outcome = "applied"
		if slices.Contains(call.Args, "--check") {
			outcome = "would-apply"
		}
	}
	json.NewEncoder(os.Stdout).Encode(map[string]any{"figaro_id": id, "version": 7, "outfit": "x", "outcome": outcome, "set": want.Set, "remove": want.Remove})
	return 0
}

func installFake(t *testing.T, plan map[string]fakeRole) (dir, log string) {
	t.Helper()
	dir = t.TempDir()
	exe, err := os.Executable()
	if err != nil {
		t.Fatal(err)
	}
	if err := os.Symlink(exe, filepath.Join(dir, "figaro")); err != nil {
		t.Fatal(err)
	}
	raw, _ := json.Marshal(plan)
	log = filepath.Join(dir, "calls.jsonl")
	t.Setenv("PATH", dir+string(os.PathListSeparator)+os.Getenv("PATH"))
	t.Setenv("FAKE_FIGARO_LOG", log)
	t.Setenv("FAKE_FIGARO_PLAN", string(raw))
	return dir, log
}

func calls(t *testing.T, log string) []fakeCall {
	t.Helper()
	f, err := os.Open(log)
	if os.IsNotExist(err) {
		return nil
	}
	if err != nil {
		t.Fatal(err)
	}
	defer f.Close()
	var out []fakeCall
	sc := bufio.NewScanner(f)
	for sc.Scan() {
		var c fakeCall
		if err := json.Unmarshal(sc.Bytes(), &c); err != nil {
			t.Fatal(err)
		}
		out = append(out, c)
	}
	return out
}

func writeManifest(t *testing.T, body string) string {
	t.Helper()
	path := filepath.Join(t.TempDir(), "roles.json")
	if err := os.WriteFile(path, []byte(body), 0o600); err != nil {
		t.Fatal(err)
	}
	return path
}

const twoRoles = `{"roles": [
  {"name": "backend-engineer", "form": "` + formA + `", "outfits": ["role-backend-engineer"], "managed": ["charter", "name", "role-name", "lanes.rou2", "standing.handoff-warm"]},
  {"name": "figaro-engineer", "form": "` + formB + `", "outfits": ["role-figaro-engineer", "extra"], "managed": ["charter", "lanes.release-engineer"]}
]}`

func runTool(t *testing.T, args ...string) (int, string, string) {
	t.Helper()
	var stdout, stderr bytes.Buffer
	code := run(args, &stdout, &stderr)
	return code, stdout.String(), stderr.String()
}

func TestManifestParsesTheCharterContract(t *testing.T) {
	m, err := loadManifest(writeManifest(t, `{"figaro": "/nix/store/x/bin/figaro", "roles": [
	  {"name": "backend-engineer", "form": "`+formA+`", "outfits": ["role-backend-engineer"], "managed": ["charter", "lanes.rou2"]}]}`))
	if err != nil {
		t.Fatal(err)
	}
	want := manifest{Figaro: "/nix/store/x/bin/figaro", Roles: []role{{Name: "backend-engineer", Form: formA, Outfits: []string{"role-backend-engineer"}, Managed: []string{"charter", "lanes.rou2"}}}}
	if fmt.Sprint(m) != fmt.Sprint(want) {
		t.Fatalf("got %+v\nwant %+v", m, want)
	}
}

func TestManifestRejectsWhatFigaroWouldMisread(t *testing.T) {
	r := func(name, form, outfits, managed string) string {
		return fmt.Sprintf(`{"name": %q, "form": %q, "outfits": %s, "managed": %s}`, name, form, outfits, managed)
	}
	ok := r("a", formA, `["role-a"]`, `["charter"]`)
	cases := map[string]struct{ body, want string }{
		"not json":         {`{"roles": [`, "unexpected EOF"},
		"unknown key":      {`{"roles": [` + ok + `], "mode": "apply"}`, `unknown field "mode"`},
		"no roles":         {`{"roles": []}`, "no roles declared"},
		"no name":          {`{"roles": [` + r("", formA, `["o"]`, `["k"]`) + `]}`, "role 0 has no name"},
		"twice by name":    {`{"roles": [` + ok + `,` + r("a", formB, `["o"]`, `["k"]`) + `]}`, "role a declared twice"},
		"twice by form":    {`{"roles": [` + ok + `,` + r("b", formA, `["o"]`, `["k"]`) + `]}`, "a and b both declare " + formA},
		"form not exact":   {`{"roles": [` + r("a", "@4f6f", `["o"]`, `["k"]`) + `]}`, `form "@4f6f" is not an exact form id`},
		"form without at":  {`{"roles": [` + r("a", formA[1:], `["o"]`, `["k"]`) + `]}`, "is not an exact form id"},
		"no outfits":       {`{"roles": [` + r("a", formA, `[]`, `["k"]`) + `]}`, "a: outfits is empty"},
		"no managed":       {`{"roles": [` + r("a", formA, `["o"]`, `[]`) + `]}`, "a: managed is empty"},
		"comma in managed": {`{"roles": [` + r("a", formA, `["o"]`, `["charter,name"]`) + `]}`, `managed entry "charter,name"`},
		"blank outfit":     {`{"roles": [` + r("a", formA, `[""]`, `["k"]`) + `]}`, `outfits entry ""`},
	}
	for name, c := range cases {
		t.Run(name, func(t *testing.T) {
			_, err := loadManifest(writeManifest(t, c.body))
			if err == nil || !strings.Contains(err.Error(), c.want) {
				t.Fatalf("got %v, want an error holding %q", err, c.want)
			}
		})
	}
}

func TestEachRoleGetsExactlyOneFormApply(t *testing.T) {
	for _, check := range []bool{false, true} {
		t.Run(fmt.Sprint("check=", check), func(t *testing.T) {
			_, log := installFake(t, nil)
			args := []string{"--manifest", writeManifest(t, twoRoles)}
			if check {
				args = append(args, "--check")
			}
			if code, out, errs := runTool(t, args...); code != 0 {
				t.Fatalf("exit %d\n%s%s", code, out, errs)
			}
			tail := []string{}
			if check {
				tail = []string{"--check"}
			}
			want := [][]string{
				append([]string{"form", "apply", "--id", formA, "-O", "role-backend-engineer", "--managed", "charter,name,role-name,lanes.rou2,standing.handoff-warm", "-j"}, tail...),
				append([]string{"form", "apply", "--id", formB, "-O", "role-figaro-engineer,extra", "--managed", "charter,lanes.release-engineer", "-j"}, tail...),
			}
			got := calls(t, log)
			if len(got) != len(want) {
				t.Fatalf("got %d calls, want %d: %+v", len(got), len(want), got)
			}
			for i := range want {
				if !slices.Equal(got[i].Args, want[i]) {
					t.Errorf("call %d:\n got %q\nwant %q", i, got[i].Args, want[i])
				}
			}
		})
	}
}

func TestCheckPrintsThePlanAndExitsByDrift(t *testing.T) {
	cases := map[string]struct {
		plan    map[string]fakeRole
		args    []string
		code    int
		stdout  string
		stderrs string
	}{
		"clean": {
			args:   []string{"--check"},
			stdout: "backend-engineer " + formA + ": unchanged\nfigaro-engineer " + formB + ": unchanged\n",
		},
		"drift": {
			plan:    map[string]fakeRole{formB: {Set: []string{"lanes.release-engineer"}, Remove: []string{"lanes.old"}}},
			args:    []string{"--check"},
			code:    1,
			stdout:  "backend-engineer " + formA + ": unchanged\nfigaro-engineer " + formB + ": would-apply\n  set: lanes.release-engineer\n  remove: lanes.old\n",
			stderrs: "1 of 2 roles drift",
		},
		"apply fixes drift": {
			plan:   map[string]fakeRole{formA: {Set: []string{"charter"}}},
			stdout: "backend-engineer " + formA + ": applied\n  set: charter\nfigaro-engineer " + formB + ": unchanged\n",
		},
		"one role fails, the rest still run": {
			plan:    map[string]fakeRole{formA: {Fail: "form apply: daemon unavailable"}, formB: {Set: []string{"charter"}}},
			args:    []string{"--check"},
			code:    1,
			stdout:  "backend-engineer " + formA + ": error\n  error: form apply: daemon unavailable\nfigaro-engineer " + formB + ": would-apply\n  set: charter\n",
			stderrs: "1 of 2 roles failed",
		},
		"garbled reply is an error": {
			plan:    map[string]fakeRole{formB: {Reply: "not json"}},
			code:    1,
			stdout:  "backend-engineer " + formA + ": unchanged\nfigaro-engineer " + formB + ": error\n  error: unreadable reply from figaro form apply: not json\n",
			stderrs: "1 of 2 roles failed",
		},
		"json rows": {
			plan:    map[string]fakeRole{formA: {Set: []string{"charter"}}},
			args:    []string{"--check", "-j"},
			code:    1,
			stdout:  `{"role":"backend-engineer","form":"` + formA + `","outcome":"would-apply","version":7,"set":["charter"]}` + "\n" + `{"role":"figaro-engineer","form":"` + formB + `","outcome":"unchanged","version":7}` + "\n",
			stderrs: "1 of 2 roles drift",
		},
	}
	for name, c := range cases {
		t.Run(name, func(t *testing.T) {
			installFake(t, c.plan)
			code, out, errs := runTool(t, append(c.args, "--manifest", writeManifest(t, twoRoles))...)
			if code != c.code || out != c.stdout || !strings.Contains(errs, c.stderrs) {
				t.Fatalf("exit %d (want %d)\nstdout:\n%s\nwant:\n%s\nstderr: %s", code, c.code, out, c.stdout, errs)
			}
			if c.stderrs == "" && errs != "" {
				t.Fatalf("clean run wrote to stderr: %s", errs)
			}
		})
	}
}

func TestUsageAndManifestFailures(t *testing.T) {
	_, log := installFake(t, nil)
	good := writeManifest(t, twoRoles)
	cases := map[string]struct {
		args []string
		code int
	}{
		"unknown flag":     {[]string{"--apply", "--manifest", good}, 2},
		"stray argument":   {[]string{"--manifest", good, "backend-engineer"}, 2},
		"help":             {[]string{"-h"}, 0},
		"missing manifest": {[]string{"--manifest", filepath.Join(t.TempDir(), "absent.json")}, 1},
		"bad manifest":     {[]string{"--manifest", writeManifest(t, `{"roles": []}`)}, 1},
	}
	for name, c := range cases {
		t.Run(name, func(t *testing.T) {
			if code, out, errs := runTool(t, c.args...); code != c.code {
				t.Fatalf("exit %d, want %d\n%s%s", code, c.code, out, errs)
			}
		})
	}
	if got := calls(t, log); len(got) != 0 {
		t.Fatalf("figaro ran on a refused invocation: %+v", got)
	}
}

func TestCallerIdentityNeverReachesFigaro(t *testing.T) {
	_, log := installFake(t, nil)
	t.Setenv("FIGARO_ARIA", "0bae436a75a440f276d357c782054b91")
	t.Setenv("FIGARO_TROUPE", "fleet")
	t.Setenv("FIGARO_CALLER", "clipboard-cubical")
	t.Setenv("FIGARO_RUNTIME_DIR", "/run/user/1000/figaro")
	if code, out, errs := runTool(t, "--manifest", writeManifest(t, twoRoles)); code != 0 {
		t.Fatalf("exit %d\n%s%s", code, out, errs)
	}
	got := calls(t, log)
	if len(got) != 2 {
		t.Fatalf("got %d calls", len(got))
	}
	for _, c := range got {
		want := map[string]string{"FIGARO_RUNTIME_DIR": "/run/user/1000/figaro"}
		if fmt.Sprint(c.Env) != fmt.Sprint(want) {
			t.Errorf("figaro saw env %v, want only %v", c.Env, want)
		}
	}
}

func TestManifestNamesTheFigaroToRun(t *testing.T) {
	dir, log := installFake(t, map[string]fakeRole{formA: {Set: []string{"charter"}}})
	t.Setenv("PATH", t.TempDir())
	body := strings.Replace(twoRoles, "{", `{"figaro": "`+filepath.Join(dir, "figaro")+`",`, 1)
	if code, out, errs := runTool(t, "--manifest", writeManifest(t, body), "--check"); code != 1 || !strings.Contains(out, "would-apply") {
		t.Fatalf("exit %d\n%s%s", code, out, errs)
	}
	if got := calls(t, log); len(got) != 2 {
		t.Fatalf("got %d calls through the manifest's figaro, want 2", len(got))
	}
}

func TestDefaultManifestLivesInFigaroConfig(t *testing.T) {
	_, log := installFake(t, nil)
	cfg := t.TempDir()
	t.Setenv("XDG_CONFIG_HOME", cfg)
	os.MkdirAll(filepath.Join(cfg, "figaro"), 0o700)
	if err := os.WriteFile(filepath.Join(cfg, "figaro", "roles.json"), []byte(twoRoles), 0o600); err != nil {
		t.Fatal(err)
	}
	if code, out, errs := runTool(t, "--check"); code != 0 {
		t.Fatalf("exit %d\n%s%s", code, out, errs)
	}
	if got := calls(t, log); len(got) != 2 {
		t.Fatalf("got %d calls, want 2", len(got))
	}
}
