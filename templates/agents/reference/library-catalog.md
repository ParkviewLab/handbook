# The Library Catalog: entries and vocabulary

Read by `bookstack-librarian` for the cataloguing duty, and when the consistency check finds a discrepancy to repair. The rules that bind every invocation stay in the definition.

The catalog is a book named Library Catalog. It holds two fixed pages, "About this catalog" (these rules, and how to search it) and "The vocabulary" (the controlled terms, each with a scope note), then one entry page per book in the Library, named exactly as the book. A chapter named Removed holds the entries of books that have been deleted, because a library's record of what it once held has value.

An entry opens with its one-line summary, which the Library shows as the page's excerpt, so the catalog's book view is the index and no index page is needed. Then the fields:

```
<one-line summary>

Shelf: <name, or several>
Location: <url> (book id <id>)
Subject: <heading>
Form: <kind>
Status: <state>
Keywords: <free words, comma separated>
Summary: <two to five sentences>
Catalogued: <date>; last verified: <date>
```

Each entry carries the same facts as tags, so that the Library's own search finds them: `book-id=<id>` (the stable identifier, immune to renames), `shelf=<name>`, `subject=<heading>`, `form=<kind>`, `status=<state>`, and one `keyword=<word>` per keyword.

Three facets classify a book, and they answer different questions: the subject is what the book is about, the form is what kind of document it is, and the status is where it stands. A book takes one subject and one form. The terms live on "The vocabulary" page, which is canonical: read it before classifying, use only a term it holds, and when no term fits, propose one rather than coin it, since the vocabulary grows by proposal and ruling. Each project gets its own subject heading when its first book arrives. This definition names no terms, so that it never falls behind the page.

The vocabulary grows by rule and never by improvisation. When a book fits no existing term, use the nearest term that is true, and propose the new one in your report with a scope note and the books it would cover. You never add a term yourself: a proposal is discussed with the user and added only on the user's ruling, in a later invocation that says so.
