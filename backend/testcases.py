import requests
import json
import sys

BASE_URL = "http://localhost:8000/extract-medicines"

# ─────────────────────────────────────────────────────────────────────────────
# ANSI colors for terminal output
GREEN  = "\033[92m"
RED    = "\033[91m"
YELLOW = "\033[93m"
CYAN   = "\033[96m"
BOLD   = "\033[1m"
RESET  = "\033[0m"

# ─────────────────────────────────────────────────────────────────────────────
# TEST DEFINITIONS
# ─────────────────────────────────────────────────────────────────────────────

TESTS = [
    # ════════ BEST CASES ════════
    {
        "name": "BEST #1 — Perfect single medicine",
        "tier": "BEST",
        "transcript": "Give him Pantoprazole 40mg once daily before food in the morning for one month.",
        "expect": {
            "count": 1,
            "medicines": [
                {
                    "name_alias": ["Pantoprazole"],
                    "frequency_alias": ["once", "1"],
                    "timing_alias": ["morning"],
                    "food_relation_alias": ["before"],
                    "duration_alias": ["month", "30 days"],
                }
            ]
        }
    },
    {
        "name": "BEST #2 — Multiple medicines",
        "tier": "BEST",
        "transcript": (
            "Prescribe the following: "
            "Metformin 500mg twice a day after food for one month. "
            "Atorvastatin 10mg once at night after food for one month. "
            "Aspirin 75mg once a day after food for one month."
        ),
        "expect": {
            "count": 3,
            "medicines": [
                {"name_alias": ["Metformin"], "frequency_alias": ["twice", "2"], "food_relation_alias": ["after"]},
                {"name_alias": ["Atorvastatin"], "timing_alias": ["night"], "food_relation_alias": ["after"]},
                {"name_alias": ["Aspirin"], "frequency_alias": ["once", "1"], "food_relation_alias": ["after"]},
            ]
        }
    },
    {
        "name": "BEST #3 — No medicines at all",
        "tier": "BEST",
        "transcript": "The patient looks fine. Come back after two weeks for a follow up.",
        "expect": {
            "count": 0,
            "medicines": []
        }
    },

    # ════════ AVERAGE CASES ════════
    {
        "name": "AVG #1 — Inference needed (missing timing/food)",
        "tier": "AVERAGE",
        "transcript": "Start him on Pantoprazole 40mg and Metformin 500mg twice daily.",
        "expect": {
            "count": 2,
            "medicines": [
                {
                    "name_alias": ["Pantoprazole"],
                    "food_relation_alias": ["before"],  # Inferred
                    "timing_alias": ["morning"],       # Inferred
                },
                {
                    "name_alias": ["Metformin"],
                    "food_relation_alias": ["after"],   # Inferred
                }
            ]
        }
    },
    {
        "name": "AVG #2 — STT noise and filler words",
        "tier": "AVERAGE",
        "transcript": "Uhh so give him uhh... Cetirizine okay, Cetirizine 10mg uhh once at night, after food, for 5 days.",
        "expect": {
            "count": 1,
            "medicines": [
                {
                    "name_alias": ["Cetirizine"],
                    "frequency_alias": ["once", "1"],
                    "timing_alias": ["night"],
                    "food_relation_alias": ["after"],
                    "duration_alias": ["5", "five"],
                }
            ]
        }
    },
    {
        "name": "AVG #3 — Duration inferred",
        "tier": "AVERAGE",
        "transcript": "Give Azithromycin 500mg once daily after food.",
        "expect": {
            "count": 1,
            "medicines": [
                {
                    "name_alias": ["Azithromycin"],
                    "frequency_alias": ["once", "1"],
                    "food_relation_alias": ["after"],
                    "duration_not_empty": True, # Should infer 3-5 days
                }
            ]
        }
    },

    # ════════ WORST CASES ════════
    {
        "name": "WORST #1 — Heavy STT corruption",
        "tier": "WORST",
        "transcript": "Give him panta pra zole forty mg in the morning and met formin five hundred mg twice daily after food.",
        "expect": {
            "count": 2,
            "medicines": [
                {"name_alias": ["Pantoprazole"]}, # The LLM must fix the spelling
                {"name_alias": ["Metformin"]},
            ]
        }
    },
    {
        "name": "WORST #2 — Brand names translated to chemical properties via inference",
        "tier": "WORST",
        "transcript": "Prescribe Dolo 650 thrice daily after food for 3 days and Thyronorm 50mcg every morning before food.",
        "expect": {
            "count": 2,
            "medicines": [
                {
                    "name_alias": ["Dolo", "Paracetamol"],
                    "frequency_alias": ["thrice", "3", "three"],
                    "food_relation_alias": ["after"],
                },
                {
                    "name_alias": ["Thyronorm", "Levothyroxine"],
                    "timing_alias": ["morning"],
                    "food_relation_alias": ["before"],
                }
            ]
        }
    },
    {
        "name": "WORST #3 — Rambling doctor, buried details",
        "tier": "WORST",
        "transcript": (
            "So uhh the patient has been having this acidity problem right, "
            "so what we'll do is we'll start with a PPI, let's go with "
            "Rabeprazole 20mg okay, once in the morning, and uhh also "
            "he has a fever so paracetamol as needed, thrice a day after food, "
            "maybe for 3 days, should be fine."
        ),
        "expect": {
            "count": 2,
            "medicines": [
                {
                    "name_alias": ["Rabeprazole"],
                    "timing_alias": ["morning"],
                    "food_relation_alias": ["before"], 
                },
                {
                    "name_alias": ["Paracetamol"],
                    "frequency_alias": ["thrice", "3", "three", "as needed"],
                    "duration_alias": ["3", "three"],
                }
            ]
        }
    }
]

# ─────────────────────────────────────────────────────────────────────────────
# ASSERTION ENGINE (Order Agnostic & Flexible)
# ─────────────────────────────────────────────────────────────────────────────

def flexible_match(actual_value: str, aliases: list) -> bool:
    """Checks if ANY of the aliases exist in the actual value."""
    actual_lower = actual_value.lower()
    return any(alias.lower() in actual_lower for alias in aliases)

def check_medicine_fields(actual: dict, expected: dict) -> list[str]:
    """Validates the properties of a matched medicine."""
    failures = []
    med_name = actual.get("medicine_name", "UNKNOWN")

    # Map the JSON keys to our test aliases
    field_mappings = {
        "food_relation": "food_relation_alias",
        "timing": "timing_alias",
        "frequency": "frequency_alias",
        "duration": "duration_alias"
    }

    for json_key, alias_key in field_mappings.items():
        if alias_key in expected:
            if not flexible_match(actual.get(json_key, ""), expected[alias_key]):
                failures.append(f"  [{med_name}] {json_key}: expected one of {expected[alias_key]}, got '{actual.get(json_key)}'")

    # Empty checks
    if expected.get("duration_not_empty"):
        val = actual.get("duration", "").strip().lower()
        if not val or val in ("not specified", "none", "null", ""):
            failures.append(f"  [{med_name}] duration: expected non-empty inferred value, got '{val}'")

    if expected.get("frequency_not_empty"):
        val = actual.get("frequency", "").strip().lower()
        if not val or val in ("not specified", "none", "null", ""):
            failures.append(f"  [{med_name}] frequency: expected non-empty inferred value, got '{val}'")

    return failures

def run_test(test: dict) -> bool:
    tier   = test["tier"]
    name   = test["name"]
    expect = test["expect"]

    tier_color = {"BEST": GREEN, "AVERAGE": YELLOW, "WORST": RED}[tier]
    print(f"\n{tier_color}{BOLD}[{tier}]{RESET} {name}")
    print(f"  {CYAN}Input:{RESET} {test['transcript'][:120]}{'...' if len(test['transcript']) > 120 else ''}")

    # Call API
    try:
        resp = requests.post(BASE_URL, json={"transcript": test["transcript"]}, timeout=90)
        
        # Intercept Pydantic 422 Errors to show exactly what went wrong
        if resp.status_code == 422:
            print(f"  {RED}✗ PYDANTIC VALIDATION ERROR:{RESET}")
            print(f"    The LLM missed a required field or returned bad JSON.")
            print(f"    Details: {json.dumps(resp.json(), indent=2)}")
            return False
            
        resp.raise_for_status()
        data = resp.json()
        
    except requests.exceptions.ConnectionError:
        print(f"  {RED}✗ CONNECTION ERROR — is the server running?{RESET}")
        return False
    except Exception as e:
        print(f"  {RED}✗ REQUEST FAILED: {e}{RESET}")
        return False

    actual_medicines = data.get("medicines", [])
    expected_medicines = expect.get("medicines", [])
    failures = []

    # 1. Check total count
    if len(actual_medicines) != expect["count"]:
        failures.append(f"  Medicine count: expected {expect['count']}, got {len(actual_medicines)}")
        print(f"  {CYAN}Output Data:{RESET} {json.dumps(data, indent=2)}")

    # 2. Order-Agnostic Matching
    # We copy the list so we can remove items as we match them
    unmatched_actual = list(actual_medicines) 

    for exp_med in expected_medicines:
        matched_idx = -1
        
        # Try to find a medicine in the actual response that matches this expected medicine
        for i, act_med in enumerate(unmatched_actual):
            if flexible_match(act_med.get("medicine_name", ""), exp_med["name_alias"]):
                matched_idx = i
                break
        
        if matched_idx == -1:
            failures.append(f"  Missing Medicine: Could not find any medicine matching {exp_med['name_alias']}")
            continue
            
        # Pop the matched medicine so we don't match it again
        matched_med = unmatched_actual.pop(matched_idx)
        
        # Check all the specific fields for this matched medicine
        field_failures = check_medicine_fields(matched_med, exp_med)
        failures.extend(field_failures)

    if failures:
        print(f"  {RED}✗ FAILED:{RESET}")
        for f in failures:
            print(f"{RED}{f}{RESET}")
        return False
    else:
        print(f"  {GREEN}✓ PASSED{RESET}")
        return True


# ─────────────────────────────────────────────────────────────────────────────
# MAIN RUNNER
# ─────────────────────────────────────────────────────────────────────────────

def main():
    print(f"\n{BOLD}{'═'*60}")
    print("  DocScribe LLM Engine — Test Suite")
    print(f"{'═'*60}{RESET}")

    results = {"BEST": [], "AVERAGE": [], "WORST": []}

    for test in TESTS:
        passed = run_test(test)
        results[test["tier"]].append(passed)

    # Summary Output
    print(f"\n{BOLD}{'─'*60}")
    print("  SUMMARY")
    print(f"{'─'*60}{RESET}")

    total_pass = 0
    total_fail = 0

    for tier, color in [("BEST", GREEN), ("AVERAGE", YELLOW), ("WORST", RED)]:
        passed = sum(results[tier])
        total  = len(results[tier])
        failed = total - passed
        total_pass += passed
        total_fail += failed
        status = f"{passed}/{total}"
        
        # Visual progress bar
        bar = "█" * passed + "░" * failed
        print(f"  {color}{BOLD}{tier:<10}{RESET}  {bar}  {color}{status}{RESET}")

    print(f"\n  {BOLD}Total: {total_pass}/{total_pass + total_fail} passed{RESET}")

    if total_fail == 0:
        print(f"  {GREEN}{BOLD}All tests passed ✓{RESET}")
    else:
        print(f"  {RED}{BOLD}{total_fail} test(s) failed ✗{RESET}")

    print()

if __name__ == "__main__":
    main()