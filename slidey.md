class: center, middle
# If you can't remember history, rewrite it so you can.
???
notes

---
name: erg
layout: true
class: middle, erg
---
## Brian Gottreu

## Minnesota Population Center

### University of Minnesota
???
System administrator at the Minnesota Population Center at the University of Minnesota.

One big thing the we do is disseminate census data after harmonizing it across space and time.

In the early to mid 90s our webapps started in Perl, went to Java, now in Ruby/JRuby.

Emporium of Perl code -- about a hundred command line utilities in Perl
Some number of modules that support them, which means we have a DarkPAN too.

Social scientists are writing Perl.

---
# What is history?
???
history is everything that lead up to now

for git, it's all the ancestors of the branch or commit that you're looking at.

it's a chain of commits

commits can share history.

---
# What is a commit?
---
#commit
A commit consists of 
+ a tree (SHA-1)
+ author info
+ committer info
+ commit message
+ any number of parents (SHA-1)

A commit's name is roughly a SHA-1 hash of all those parts.
```default
a894952bdba206d18c6cd17c1eb565e856b3f26b
```
???
tree = directory of files (files are called blobs)

There are length fields and seperators.

sha1sum file != SHA-1 of blob

If any of those parts change, the SHA-1 changes, and you have a new commit.

You can't change a commit.

But you can change a commit-ish.

---
#commit-ish

A commit object or an object that can be recursively dereferenced to a commit object.
???
commit object

tag object that points to a commit

---
#refs

A name that begins with refs/ (e.g.  refs/heads/master) that points to an object name or another ref (the latter is called a symbolic ref).
???
you can also change refs, that is branches and tags.

refs are a human readable name that points to objects (or other refs).

so the readable name stays the same, but the SHA-1 it points to can change.
---
```shell
$ cat .git/refs/heads/master
b8fe23f4fab06e79d18881a2540f54ec61fee8ef
```
???
This is what happens to a branch every time you commit.  A new commit object is created and 
your current branch is updated to point to that new commit.

branches might be commit-ish?

branches are refs and refer to commits,  but they may not be technically commit-ish.

---
#Rewriting history
???
Making new commits based off old commits.

which could mean making new trees (directories) and new blobs (files).

and then updating tag objects and refs.

a lot of the downsides of rewriting history stem from the changing of tags and branches

and making collaboration difficult

bad things happen when a 
refname is used to mean more than one thing.

Pushes and pulls can break.

People will be mad at you.

---
```
Date: Sat, 17 May 2014 22:02:39 -0400
From: Ricardo Signes <perl.p5p@rjbs.manxome.org>
To: perl5-porters@perl.org
Subject: **I rewound blead**

I rewound blead one commit, resetting it to e023b52, eliminating a bad merge.

I did not do this lightly, and I don't plan to make a habit of it.

rjbs
```
???
this did not involve rewriting history, only changing what blead (a ref) referred to.

---
Sometimes there are things in a repo that must not be there.
--

+ Passwords
+ SSH or SSL keys
???
if the repo is private then things can be removed prior to
public release or just because secrets should not be in a repo.

A project had passwords in a private repo.

And a developer had a checkout of that code (as you do).

Then this checkout, along with the rest of his laptop, was stolen.

If the repo is or was public change all exposed passwords and keys.
The damage is done, removing things now might not be worth it.

---
Sometimes there are things in a repo that should not be there.
--

+ Binary files
+ Large files
+ Junk
???
git doesn't handle revisions to binary files well

really large files (like several gigs) makes cloning a pain

other useless things:  foo.pl.bak or derivatives of the source
that should not have entered git at all.

---
Sometimes there are things in a repo that you just don't want there.
???
dumb changes that got merged in.

terrible commit messages that are completely unhelpful.

---
git-filter-branch - Rewrite branches
???
We'll start rewriting with good old git filter branch.  This is what the man page says.

---
```default
NAME
       git-filter-branch - Rewrite branches

SYNOPSIS
       git filter-branch [--env-filter <command>] [--tree-filter <command>]
               [--index-filter <command>] [--parent-filter <command>]
               [--msg-filter <command>] [--commit-filter <command>]
               [--tag-name-filter <command>] [--subdirectory-filter <directory>]
               [--prune-empty]
               [--original <namespace>] [-d <directory>] [-f | --force]
               [--] [<rev-list options>...]
```
???
When a rev-list is not specified
git-filter branch starts at HEAD and rewrites all the ancestors using the filters provided.

That means if you are on master and rewrite, then other branches will not be written.
If you specify --all for rev-list then all branches get rewritten.

---
# Moving everything out of a subdirectory
???
svn to git migration

but all the files are under a rails/ directory

this is annoying to deal with, so a developer moved everything to the base directory

---
```shell
git mv rails/* .
git commit
```
???
It made the future better, but the past worse.

Since it was a pretty new repo, they could have done a filter-branch right there.

git log filename requires --follow (or setting the config parameter) 

git bisect and friends won't work (or will be harder to work with)

What they could have done is a filter branch with a subdirectory filter.

---
```shell
git filter-branch --subdirectory-filter rails \
--tag-name-filter cat -- --all
```
???
That would move the files in HEAD and in all previous commits.

But that wasn't done, however we could still do a tree-filter.

---
```shell
git filter-branch --tree-filter 'git mv -k rails/* .' \
--tag-name-filter cat -- --all
```
???
For every revision, it checks out the commit, performs the filter on it, then commits it with the author info and commit message.

This is fragile, if anything already exists outside of rails/ then this would fail to overwrite it.  (which might be what we want)

---
# Removing passwords
???
To remove passwords we can use another tree filter.

---
database.yml
```yaml
live:
  username: live_user
  password: secret123

test:
  username: tester
  password: ssshhhh
```

---

```shell
git filter-branch --tree-filter \
'perl -i -pe "s/password:.+/password:/" database.yml' \
--prune-empty --tag-name-filter cat -- --all
```
???
this will yank out the password for all commits

prune empty would remove a commit when all the commit is, is changing a password.

inefficient

---
#BFG Repo-Cleaner
???
scala based (runs on jvm), faster, doesn't checkout anything

git manual recommends it

how it works roughly  (TODO: fill in this part)

---
../remove.txt
```default
regex:password:.+==>password:
```

```shell
java -jar ~/bin/bfg.jar --replace-text ../remove.txt --no-blob-protection .
```
???
efficient, but the replacements are not complex enough for
my ERB YAML needs

---
#Why not just keep database.yml out of the repo?
???
some things should be in a repository:
+ database names
+ specific drivers (mysql vs pg vs sqlite)
+ connection parameters (pooling connections, timeouts)

Those all should remain in the repo.

---
database.yml
```yaml
live:
  username: live_user
  password: <%= get_password("live") %>

test:
  username: tester
  password: <%= get_password("test") %>
```
???
In Rails database.yml is run through ERB. (a template system)

Ideally all the non-secrets stay in the repo and only the secrets are removed.

---
#It's over
