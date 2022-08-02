# Sources

This is a tentative guide for Ferrite sources. The source format can change at any time without warning throughout the duration of the alpha so do not jump the gun if you don't want to.

## Source lists

Source lists must adhere to the following template. All of these fields are `required` to properly add a source to Ferrite.

(Note: Name and author fields are not enforced, but they will be in future versions of Ferrite)

```json
{
    "name": "Repository name",
    "author": "Repository author",
    "sources": ["source objects go here"]
}
```

## Creating a source object

Here is a quick template to what a source entry looks like with all the possible parameters. You can copy/paste this template into your editor of choice. I will go through all the keys one-by-one.

```json
{
    "name": "Website (source) name",
    "version": "1",
    "baseUrl": "https://sourceurl.com",
    "htmlParser": {
        "searchUrl": "?q={query}",
        "rows": "row selector",
        "magnet": {
            "query": "magnet selector",
            "externalLinkQuery": "https://sourceurl.com/magnetUrl"
            "attribute": "href",
            "regex": "regex"
        },
        "title": {
            "query": "title selector",
            "attribute": "text",
            "regex": "regex"
        },
        "size": {
            "query": "size selector",
            "attribute": "text",
            "regex": "regex"
        },
        "sl": {
            "seeders": "seeder selector",
            "leechers": "leecher selector",
            "combined": "seeder/leecher ratio selector",
            "seederRegex": "regex",
            "leecherRegex": "regex"
        }
    }
}
```

### name

`Required`: This is the name that is shown when the user is looking at a source

### version

`Required`: This is the version number of the source. Each update to the source increments the version by 1. Only increment the version when you are sure that the source is ready to be published.

### baseUrl

`Required`: The base URL of the website. For example, `https://google.com` is the base URL of Google. DO NOT include the slash on the end of the base URL otherwise the source will break.

### htmlParser

`Optional`: The web scraping module for a source. Use this if a source does not have an API and allows scraping! (NOTE: API support will be added in a future build of Ferrite, use the htmlParser for now)

### searchUrl

`Required for htmlParser`: The URL given when searching content on a website. For example, when given a URL such as `https://www.google.com/search?q=hello`, the search URL is whatever comes after the base URL (in this case `/search?q=hello`). It is important to include the slash at the beginning otherwise the source will break.

### rows

`Required for htmlParser`: The CSS selector for selecting a table row. Most of these sites use HTML tables. Please consult this while web scraping.

### magnet

`Required for htmlParser`: A complex query. Please reference complex queries to understand the other keys. Unique keys are provided below:

- externalLinkQuery: If a magnet link is located on a different page, this fetches the URL required to navigate to that page and fetch the magnet link.

### title

`Optional for htmlParser`: This is a complex query. Please reference complex queries to understand the keys

### size

`Optional for htmlParser`: This is a complex query. Please reference complex queries to understand the keys

### sl (seeders and leechers)

`Optional for htmlParser`: Used to get seeder and leecher values on a website. All the below properties are optional.

- seeders: The seeder CSS selector

- leechers: The leecher CSS selector

- combined: A CSS selector used when seeders and leechers are in one string (ex. `Seeders: 100 / Leechers: 200`)

- seederRegex: Regex used to strip the seeder value from a string (follows the same rules as complex query regexes)

- leecherRegex: Regex used to strip the leecher value from a string (follows the same rules as complex query regexes)

## Complex queries

These are generic queries used by Ferrite for keys that require a little more information when parsing the contents. Any key that has a complex query disclaimer will always use these parameters:

- query `Required`: The CSS selector for selecting the element in question

- attribute `Required`: The attribute to look for after selecting the query (ex. href, title, span). If you want the textContent, use `text` in the attribute parameter.

- regex `Optional`: Runs regex on the query result before presentation to the user.
  
  - Do not include the beginning and end slashes in this string (ex. `/regex/`)
  
  - When using a `\` character, escape it using `\\`
  
  - This regex must have only one capturing group. [Don't know what a capture group is?](https://www.regular-expressions.info/brackets.html)
