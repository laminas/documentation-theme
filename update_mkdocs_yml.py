#!/usr/bin/env python3
import os
import sys
import yaml

def extract_from_branch_ref(ref: str) -> str:
    # Ref looks like "refs/heads/foo/bar"
    # split by "/" and kept branch name (["foo", "bar"])
    ref_parts = ref.split('/')[2:]
    # join the parts again
    return "/".join(ref_parts)

def extract_from_tag_ref(ref: str) -> str:
    # Ref looks like "refs/tags/1.2.3"
    # split by "/" and kept version number ("1.2.3")
    # Then split again and replace patch number with "x"
    version = ref.split('/')[-1].split('.')
    version[2] = 'x'
    # join the parts again
    return ".".join(version)
    
if len(sys.argv) < 3:
    print("Missing required arguments to update_mkdocs_yml.py.\n")
    print("Usage:\n")
    print("  update_mkdocs_yml.py <SITE_URL> <DOCS_DIR>\n")
    exit(1)

site_url = sys.argv[1]
docs_dir = sys.argv[2]

ref = os.getenv('GITHUB_REF')
branch = 'master'
if ref is not None:
    if 'refs/heads' in ref:
        branch = extract_from_branch_ref(ref)
    elif 'refs/tags' in ref:
        branch = extract_from_tag_ref(ref)

with open("mkdocs.yml") as f:
    mkdocs = yaml.load(f, Loader=yaml.SafeLoader)

mkdocs["site_url"] = site_url
mkdocs["edit_uri"] = f'edit/{branch}/{docs_dir}/'
mkdocs["markdown_extensions"] = [
        {
            "markdown.extensions.codehilite": {
                "use_pygments": False
            }
        },
        "markdown.extensions.attr_list",
        "markdown.extensions.md_in_html",
        "markdown.extensions.def_list",
        "pymdownx.superfences",
        "pymdownx.tabbed",
        {
            "pymdownx.snippets": {
                "url_download": True,
                "base_path": [
                    "docs/snippets"
                ]
            }
        },
        {
            "toc": {
                "toc_depth": 2
            }
        },
        "callouts"
    ]

mkdocs["theme"] = {
        "name": None,
        "custom_dir": "documentation-theme/theme",
        "static_templates": [
            "pages/404.html"
        ]
    }

# Remove any trailing slashes from the end of the repo_url
mkdocs["repo_url"] = mkdocs["repo_url"].rstrip("/")
mkdocs["extra"]["repo_name"] = mkdocs["repo_url"].replace("https://github.com/", "")
mkdocs["extra"]["base_url"] = "https://docs.laminas.dev/"

if mkdocs["extra"]["project"] == "Components":
    mkdocs["extra"]["project_url"] = "https://docs.laminas.dev/components/"
elif (mkdocs["extra"]["project"] == "MVC") or (mkdocs["extra"]["project"] == "Mvc"):
    mkdocs["extra"]["project_url"] = "https://docs.laminas.dev/mvc/"
elif mkdocs["extra"]["project"] == "Mezzio":
    mkdocs["extra"]["project_url"] = "https://docs.mezzio.dev/"

# If plugins are set, check if search exists
# https://www.mkdocs.org/user-guide/configuration/#plugins
if "plugins" in mkdocs and not "search" in mkdocs["plugins"]:
    mkdocs["plugins"].append("search")

with open("mkdocs.yml", "w") as f:
    yaml.dump(mkdocs, f, default_flow_style=False)
