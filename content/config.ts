import { z, defineCollection } from 'astro:content'

const postsCollection = defineCollection({
    type: 'content',
    schema: z.object({
        title: z.string(),
        author: z.string(),
        date: z.date(),
        update: z.date().optional(),
        tags: z.array(z.string()).optional(),
    })
})

export const collections = {
    'posts': postsCollection,
}