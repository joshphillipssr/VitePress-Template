// docs/.vitepress/config.mts
import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'joshphillipssr.com',
  description: 'Docs',
  head: [
    ['link', { rel: 'canonical', href: 'https://joshphillipssr.com' }]
  ],
  sitemap: {
    hostname: 'https://joshphillipssr.com',
    lastmodDateOnly: false,
    transformItems: (items) =>
      items
        // drop any URLs under /drafts/ (adjust/add more filters as needed)
        .filter((i) => !i.url.startsWith('/drafts/'))
        // set a default changefreq for all remaining items
        .map((i) => ({ ...i, changefreq: 'weekly' as const })),
  },
  themeConfig: {
    socialLinks: [
      { icon: 'github', link: 'https://github.com/joshphillipssr/joshphillipssr.com' }
    ],
    sidebar: [
      { text: 'Home', link: '/' },
      { text: 'Resume', link: '/Resume/' }
    ]
  }
})