// docs/.vitepress/config.ts
import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'joshphillipssr.com',
  description: 'Docs',
  themeConfig: {
    // nav: [
    //   { text: 'Home', link: '/' },
    //   { text: 'Resume', link: '/Resume/' }
    // ],
    // show on all pages
    socialLinks: [
      { icon: 'github', link: 'https://github.com/joshphillipssr/joshphillipssr.com' }
    ],
    sidebar: [
      { text: 'Home', link: '/' },
      { text: 'Resume', link: '/Resume/' }
    ]
  }
})