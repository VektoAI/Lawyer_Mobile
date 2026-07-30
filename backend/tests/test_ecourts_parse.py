from app.services.ecourts_parse import match_cases_on_entries, parse_causelist_file

SAMPLE = b"""
<html><body><table>
<tr><td>1</td><td>CS 123/2022</td><td>Ram vs Shyam</td><td>Adv. Test Lawyer</td></tr>
</table></body></html>
"""


def test_parse_html_causelist():
    entries, src = parse_causelist_file(SAMPLE, "list.html")
    assert src == "ecourts_html"
    assert len(entries) >= 1
    assert "123" in entries[0]["case_ref"]


def test_match_case_on_upload():
    entries, _ = parse_causelist_file(SAMPLE, "list.html")
    out = match_cases_on_entries(
        entries,
        [{"client_case_id": "c1", "court_id": 2, "case_no": "CS 123/2022"}],
        "2026-07-30",
    )
    assert out["updates"][0]["found"] is True
    assert out["updates"][0]["next_date"] == "2026-07-30"
