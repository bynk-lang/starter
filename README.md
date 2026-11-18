# Bynk starter: a guestbook

A small, complete [Bynk](https://bynk-lang.org) app to start from: people sign a
guestbook over HTTP, and each guestbook keeps its own entries. It has tests,
CI, a deploy to Cloudflare Workers, and a dev container, so you can run it in
a browser with nothing installed.

**Use this template** (the green button above) to make your own copy, then
follow the steps below. The walkthrough on the blog,
[Getting started with Bynk](https://bynk-lang.org/blog/posts/getting-started/),
goes through the same steps with more of the why.

## 1. Open it

**In the browser, with nothing installed.** On your copy, choose
**Code → Codespaces → Create codespace on main**. The container installs the
Bynk version in [`BYNK_VERSION`](BYNK_VERSION), Node, wrangler and the Bynk VS
Code extension. It takes a minute or two the first time.

**On your own machine.** Install Bynk ([instructions](https://bynk-lang.org/book/introduction/install/))
and Node 22 or newer, then:

```sh
git clone https://github.com/<you>/<your-copy>
cd <your-copy>
bynk doctor        # says what's missing, and how to fix it
```

Opening the folder in VS Code with the
[Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers)
extension gives you the same set-up as Codespaces.

## 2. Run the tests

```sh
bynk test .
```

You should see ten passing tests, in three groups:

- `guestbook.entries`: the pure rules, such as "a name can't be empty".
- `guestbook.app`: the guestbook agent, signed and read directly.
- `system · guestbook.app`: raw JSON sent through the HTTP service, including
  requests that should be refused.

## 3. Run the app

```sh
bynk dev
```

This serves the app on <http://localhost:8787> (Codespaces forwards the port
for you) and rebuilds when you save. In another terminal:

```sh
curl -X POST localhost:8787/books/cafe/entries \
  -H 'content-type: application/json' \
  -d '{"name": "Ada", "message": "Lovely tea."}'

curl localhost:8787/books/cafe/entries
```

Now try an empty message. Bynk refuses it before your code runs, with a `400`
that says which field broke which rule:

```sh
curl -X POST localhost:8787/books/cafe/entries \
  -H 'content-type: application/json' \
  -d '{"name": "Ada", "message": ""}'
```

## 4. Read the code

There are two source files, and it's worth reading them in this order:

| File | What it holds |
|---|---|
| [`src/guestbook/entries.bynk`](src/guestbook/entries.bynk) | A **commons**: the `Entry` type and its rules (`Name` and `Message` are *refined types*, a type with a rule attached), and one pure function. No state, no outside world, so it's easy to test. |
| [`src/guestbook/app.bynk`](src/guestbook/app.bynk) | A **context**: the `Guestbook` **agent**, which keeps the entries (on Cloudflare, one Durable Object per guestbook), and the HTTP **service** in front of it. |

The tests mirror them, in [`tests/guestbook/`](tests/guestbook/).

## 5. Make a change

A good first change: let people rate their visit from 1 to 5.

1. In `entries.bynk`, add a refined type and a field on `Entry`:

   ```bynk
   --- A rating from 1 to 5.
   type Rating = Int where InRange(1, 5)
   ```

   and `rating: Rating,` inside `Entry`.
2. Run `bynk check .`. The compiler now points at every place that builds an
   `Entry` without a rating, in the tests. Add `rating: 5` (or any number from
   1 to 5) to each.
3. The compiler can't see inside the raw JSON in
   `tests/guestbook/boundary.bynk`, so add `"rating": 5` to the JSON there
   yourself. Then add a test that a rating of `6` is refused: copy the "an
   empty message is refused" case and change its JSON.
4. Run `bynk test .` and `bynk dev` again, and try a rating of 6 with `curl`.

Nothing else changes: the service checks the new field on the way in, and the
agent stores it, because both work in terms of `Entry`.

## 6. Deploy it

The [Deploy workflow](.github/workflows/deploy.yml) deploys to Cloudflare
Workers on every push to `main`, once you add two repository secrets
(**Settings → Secrets and variables → Actions**):

| Secret | Value |
|---|---|
| `CLOUDFLARE_API_TOKEN` | A Cloudflare API token with permission to edit Workers |
| `CLOUDFLARE_ACCOUNT_ID` | Your Cloudflare account ID |

Until then it skips the deploy with a warning, and pull requests get a dry run
that shows what would be deployed. To deploy from your own machine instead,
run `bynk deploy`, which asks wrangler to sign you in.

The first deploy writes `bynk.deploy.lock`, which records what was deployed.
Commit it: the workflow uploads it as an artifact named `bynk.deploy.lock` when
it changes.

A build also writes `bynk.schema.lock`, which records the shape of the data
your agents store. Commit that too. From then on, the compiler refuses a change
that stored entries couldn't be read through, such as removing a field from
`Entry`, and explains how to make the change safely.

## Keeping Bynk up to date

[`BYNK_VERSION`](BYNK_VERSION) names the Bynk release this project uses. CI and
the dev container both read it, so they always agree. To move to a newer
release, change it, run the tests, and rebuild your codespace
(**Codespaces: Rebuild Container**).

## Where next

- [The Bynk Book](https://bynk-lang.org/book/): tutorials, guides and the
  reference.
- [Coming from TypeScript](https://bynk-lang.org/book/introduction/coming-from-typescript/),
  if that's where you're starting.
- [The showcase](https://github.com/bynk-lang/showcase): small projects, one
  feature each, to borrow from.
- [The blog](https://bynk-lang.org/blog/): the thinking behind the language,
  one problem at a time.

## Licence

Licensed under either of [MIT](LICENSE-MIT) or [Apache-2.0](LICENSE-APACHE), at
your option.
