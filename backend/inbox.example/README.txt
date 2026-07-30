# Example inbox filename: {court_id}_{YYYY-MM-DD}.html
# Court ids: 2 District Dehradun, 3 Family, 4 UK HC, 5 Civil Judge, 6 MACT, 7 DRT Dehradun
# Ops drops one HTML cause list per court per day; cron parses into data/causelist_cache/
# Lawyers never upload — app sync-hearings reads cache only.
