import json
data = json.load(open(r'D:\Temp\cruddy-v040\qa_validation_v2.json', encoding='utf-8'))
per_file = data['per_file']
print('Total agents:', len(per_file))
pass_count = 0
fail_count = 0
for r in per_file:
    reasons = []
    if not r['parse_ok']:
        reasons.append('parse')
    if r['fields_missing']:
        reasons.append('fields')
    if r['triggers_bad_format']:
        reasons.append('triggers')
    if r['forbidden_triggers_bad_format']:
        reasons.append('forbidden')
    if not r['when_quoted']:
        reasons.append('when-not-quoted')
    if not r['handoff']['has_handoff_heading']:
        reasons.append('handoff-heading')
    if not r['handoff']['has_dispatch_to']:
        reasons.append('dispatch-to')
    if not r['handoff']['has_routes_to_me']:
        reasons.append('routes-to-me')
    if r['handoff'].get('has_dispatch_to') and r['handoff'].get('has_routes_to_me') and not r['handoff'].get('position_ok'):
        reasons.append('handoff-order')
    if reasons:
        fail_count += 1
        print(f"FAIL {r['file']}: {reasons}")
    else:
        pass_count += 1
print(f"Pass: {pass_count}, Fail: {fail_count}")

ss = next(r for r in per_file if r['file'] == 'standup-summary.md')
print()
print('standup-summary self-check verification:')
print(f"  line count 200-300: actual={ss['line_count']}  in_range={200 <= ss['line_count'] <= 300}")
print(f"  triggers == 12: actual={ss['trigger_count']}  match={ss['trigger_count'] == 12}")
print(f"  forbidden == 7: actual={ss['forbidden_trigger_count']}  match={ss['forbidden_trigger_count'] == 7}")

print()
print('trigger overlaps (corpus-wide):')
for t, agents in sorted(data['trigger_overlaps'].items()):
    print(f"  '{t}' -> {agents}")