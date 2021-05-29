#!/usr/bin/env python3
import sys
import yaml

if len(sys.argv) < 3:
    print("Missing required arguments to update_mkdocs_yml.py.\n")
    print("Usage:\n")
    print("  update_mkdocs_yml.py <SITE_URL> <DOCS_DIR>\n")
    exit(1)

site_url = sys.argv[1]
docs_dir = sys.argv[2]

with open("mkdocs.yml") as f:
    mkdocs = yaml.load(f, Loader=yaml.SafeLoader)

mkdocs["site_url"] = site_url
mkdocs["edit_uri"] = 'edit/master/{}/'.format(docs_dir)
mkdocs["markdown_extensions"] = [
        {
            "markdown.extensions.codehilite": {
                "use_pygments": False
            }
        },
        "markdown.extensions.attr_list",
        "markdown.extensions.md_in_html",
        "pymdownx.superfences",
        "pymdownx.tabbed",
        {
            "toc": {
                "toc_depth": 2
            }
        }
    ]

mkdocs["theme"] = {
        "name": None,
        "custom_dir": "documentation-theme/theme",
        "static_templates": [
            "pages/404.html"
        ]
    }

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
