// The site of an abap2UI5 addon on GitHub Pages
// (https://abap2ui5-addons.github.io/<repo>/), built with VitePress by
// `npm run site` and deployed by .github/workflows/deploy-pages.yaml.
//
// The same file in every addon - what differs is in ../site.json (the
// repository, its branch, the title and extra menu entries), so every addon
// site has the same menu, the same pages and the same look:
//   Home       index.md - what it is, requirements, installation, a first app
//   Guide      guide.md - the README, included as it is
//   Changelog  changelog.md - CHANGELOG.md, where the repository has one
// Relative links of the README point into the repository; on the site they
// are rewritten to GitHub, where the file is (markdown.config below).
import { existsSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { defineConfig } from "vitepress";

type NavItem = { text: string; link: string };
const here = dirname(fileURLToPath(import.meta.url));
const site = JSON.parse(readFileSync(join(here, "..", "site.json"), "utf8")) as {
  repo: string;
  org?: string;
  branch?: string;
  title: string;
  description: string;
  nav?: NavItem[];
};
const ORG = site.org ?? "abap2UI5-addons";
const BRANCH = site.branch ?? "main";
const REPO = `https://github.com/${ORG}/${site.repo}`;
const ROOT = join(here, "..", "..");
const hasChangelog = existsSync(join(here, "..", "changelog.md"));

// a link of the README relative to the repository: to its file on GitHub
function toGitHub(href: string, image: boolean): string {
  if (/^([a-z]+:|#|\/|mailto:)/i.test(href)) return href;
  const path = href.replace(/^\.\//, "");
  return image ? `${REPO}/raw/${BRANCH}/${path}` : `${REPO}/blob/${BRANCH}/${path}`;
}

export default defineConfig({
  title: site.title,
  description: site.description,
  lang: "en",
  base: `/${site.repo}/`,
  outDir: join(ROOT, "build", "site"),
  cleanUrls: true,
  lastUpdated: true,
  head: [["link", { rel: "icon", type: "image/png", href: `/${site.repo}/favicon.png` }]],
  markdown: {
    config(md) {
      // only the pages that include a file of the repository (frontmatter
      // `source: repository`) have links relative to its root
      md.core.ruler.push("repository-links", (state) => {
        if (state.env?.frontmatter?.source !== "repository") return;
        // the same for src / href of raw HTML (<img src="img/a.png">)
        const html = (content: string) =>
          content.replace(/\b(src|href)="([^"]*)"/g, (_m, attr: string, url: string) =>
            `${attr}="${toGitHub(url, attr === "src")}"`);
        for (const block of state.tokens) {
          if (block.type === "html_block") block.content = html(block.content);
          for (const token of block.children ?? []) {
            if (token.type === "link_open") token.attrSet("href", toGitHub(token.attrGet("href") ?? "", false));
            if (token.type === "image") token.attrSet("src", toGitHub(token.attrGet("src") ?? "", true));
            if (token.type === "html_inline") token.content = html(token.content);
          }
        }
      });
    },
  },
  themeConfig: {
    logo: "/favicon.png",
    nav: [
      { text: "Guide", link: "/guide" },
      ...(site.nav ?? []),
      ...(hasChangelog ? [{ text: "Changelog", link: "/changelog" }] : []),
      {
        text: "abap2UI5",
        items: [
          { text: "All addons", link: "https://abap2ui5-addons.github.io/" },
          { text: "abap2UI5", link: "https://abap2ui5.github.io/" },
          { text: "Documentation", link: "https://abap2ui5.github.io/docs/" },
        ],
      },
    ],
    socialLinks: [{ icon: "github", link: REPO }],
    editLink: { pattern: `${REPO}/edit/${BRANCH}/site/:path`, text: "Edit this page on GitHub" },
    search: { provider: "local" },
    outline: { level: [2, 3] },
    footer: {
      message: `MIT licensed - part of <a href="https://abap2ui5-addons.github.io/">abap2UI5-addons</a>`,
      copyright: `<a href="${REPO}">${ORG}/${site.repo}</a> on GitHub`,
    },
  },
});
