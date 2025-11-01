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
    sidebar: [
      { text: 'Home', link: '/' },
      { text: 'Resume', link: '/Resume/' }
    ]
  }
})