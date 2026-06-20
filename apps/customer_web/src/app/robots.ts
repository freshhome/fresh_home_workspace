import { MetadataRoute } from 'next';

export default function robots(): MetadataRoute.Robots {
  return {
    rules: {
      userAgent: '*',
      allow: '/',
      disallow: ['/booking', '/orders'], // Disallow crawling transactional pages for privacy protection
    },
    sitemap: 'https://freshhome-egypt.com/sitemap.xml',
  };
}
