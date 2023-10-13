const {
    description
} = require('../package')

module.exports = {
    head: [
        ['meta', {
            name: 'theme-color',
            content: '#3eaf7c'
        }],
        ['meta', {
            name: 'apple-mobile-web-app-capable',
            content: 'yes'
        }],
        ['meta', {
            name: 'apple-mobile-web-app-status-bar-style',
            content: 'black'
        }],
        ["link", {
            rel: "'stylesheet",
            href: "/styles/website.css"
        },]
    ],
    locales: {
        '/': {
            lang: 'zh-CN',
            title: 'ARPL-I18n使用指南',
            description: 'ARPL-I18n使用指南 - Ver.0.0.1'
    },

        base: '/arpl-i18n/tree/docs/',

    watch: {
        $page(newPage, oldPage) {
            if (newPage.key !== oldPage.key) {
                requestAnimationFrame(() => {
                    if (this.$route.hash) {
                        const element = document.getElementById(this.$route.hash.slice(1));

                        if (element && element.scrollIntoView) {
                            element.scrollIntoView();
                        }
                    }
                });
            }
        }
    },

    markdown: {
        extendMarkdown: md => {
            md.use(require('markdown-it-multimd-table'), {
                rowspan: true,
            });
        }
    },

    theme: 'vuepress-theme-succinct',
    globalUIComponents: [
        'ThemeManager'
    ],

    themeConfig: {
        lastUpdated: true,//上次更新
        smoothScroll: true,//页面滚动
        repo: 'https://github.com/sumingyd/arpl-i18n/tree/docs',
        editLinks: true,
        logo: '/homepage.png',
        locales: {
            '/': {
                label: '简体中文',
                selectText: '选择语言',
                ariaLabel: '选择语言',
                editLinkText: '在 GitHub 上编辑此页',
                lastUpdated: '上次更新',
                nav: [
                    {
                        text: '指南菜单',
                        items: [
                            {
                                text: 'OpenCore安装',
                                link: 'https://sumingyd.github.io/OpenCore-Install-Guide/'
                            },
                        ]
                    },
                    { text: 'QQ群', link: 'https://jq.qq.com/?_wv=1027&k=liYHt5VH' },
                ],
                sidebar: [
                    {
                        title: '故障诊断',
                        collapsable: false,
                        children: [
                            '/troubleshooting/troubleshooting',
                            {
                                title: '',
                                collapsable: false,
                                children: [
                                    '/troubleshooting/extended/opencore-issues',
                                    '/troubleshooting/extended/kernel-issues',
                                    '/troubleshooting/extended/userspace-issues',
                                    '/troubleshooting/extended/post-issues',
                                    '/troubleshooting/extended/misc-issues',

                                ]
                            },
                            '/troubleshooting/debug',
                            '/troubleshooting/boot',
                            '/troubleshooting/kernel-debugging',
                        ]
                    },
                ],
            },
        }

    },
    plugins: [
        ['@vuepress/back-to-top', true],//开启右下角返回顶层图标
        ['@vuepress/nprogress', true],//这个插件将会在你切换页面的时候，在顶部显示进度条。
        ['vuepress-plugin-smooth-scroll', true],//在你的 VuePress 站点中使用平滑滚动。
        ['vuepress-plugin-fulltext-search', true],//基于 Headers 的搜索插件
        ['@vuepress/medium-zoom', {
            selector: ".theme-succinct-content :not(a) > img",
            options: {
                background: 'var(--bodyBgColor)'
            }
        }
        ],//这个插件将会使你的图片支持点击缩放。
        ['@vuepress/active-header-links', {
            sidebarLinkSelector: '.sidebar-link',
            headerAnchorSelector: '.header-anchor'
        }
        ],//页面滚动时自动激活侧边栏链接的插件
    ]
}
