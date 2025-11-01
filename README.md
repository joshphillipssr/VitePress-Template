# joshphillipssr.com

A clean, modern **VitePress**-based documentation and portfolio site.

This repository powers [https://joshphillipssr.com](https://joshphillipssr.com) — built from scratch using [VitePress](https://vitepress.dev) with a minimal sidebar-only layout.

---

## 🚀 Features

- ⚡️ Built with [VitePress](https://vitepress.dev)
- 🎨 Clean sidebar-only theme (no top navigation)
- 📄 Easy Markdown-based content structure
- 🧱 Designed for personal portfolios, documentation sites, or project wikis
- ☁️ Simple deployment to Nginx or GitHub Pages

---

## 🧰 Tech Stack

- **Framework:** VitePress (`vitepress@latest`)
- **Language:** TypeScript / Markdown
- **Package Manager:** Yarn
- **Hosting Example:** Nginx (Debian 12)

---

## 🗂️ Folder Structure

```
joshphillipssr.com/
├── docs/
│   ├── .vitepress/
│   │   └── config.mts
│   ├── Resume/
│   │   └── index.md
│   └── index.md
├── .gitignore
├── package.json
└── README.md
```

---

## 🏁 Getting Started

### 1. Clone this repository
```bash
git clone https://github.com/joshphillipssr/joshphillipssr.com.git
cd joshphillipssr.com
```

### 2. Install dependencies
```bash
yarn install
```

### 3. Start local development
```bash
yarn docs:dev
```

### 4. Build for production
```bash
yarn docs:build
```

The generated static files will be in `docs/.vitepress/dist`.

---

## 🌐 Deployment

To serve on Nginx or any static host:

```bash
rsync -a --delete docs/.vitepress/dist/ /var/www/example.com/
sudo systemctl reload nginx
```

For GitHub Pages:
```bash
yarn docs:build
git add docs/.vitepress/dist -f
git commit -m "Deploy site"
git subtree push --prefix docs/.vitepress/dist origin gh-pages
```

---

## 🧩 Credits

This site was built by [Josh Phillips](https://linkedin.com/in/joshphillipssr)  

---

## 🪄 License

MIT © [Josh Phillips](https://joshphillipssr.com)

You’re free to fork this repo or use it as a template to build your own VitePress site.