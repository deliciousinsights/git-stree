# stree: a better Git subtree command

**Subtrees** are a great way to share a single tree across multiple projects using it in their own codebases. For many use-cases, they are a vastly superior alternative to submodules.  Alas, there is no built-in equivalent to `git submodule` to help you properly manage subtrees.

## Why git-subtree doesn't quite cut it

A contrib script has long existed, `git-subtree`, that has now been included in the official Git distribution for some time, therefore accessible through the `git subtree` "subcommand."  It is very powerful and resilient, unfortunately it has two major drawbacks in my eyes:

  1. It uses merges, even in squash mode, which means it **pollutes the graph** with long-running, oft-merged branches for every subtree.
  2. It requires every command to **re-specify the entire subtree settings** (remote URL/name, remote branch, local tree prefix).

## What git-stree gives you

Obviously, I scratched my own itch here. So what did I want to achieve?

  * **One-time settings specification.** I want to tell Git about how my subtree works just once, when adding it. Then it should remember it for later commands.
  * **No history graph pollution.** My subtree comes from a distinct codebase, with its own history. I'm not interested in seeing that history conflated with my main codebases' histories. I'm also not interested in having my graph polluted by long-running branches for every subtree I define.  So I expect a subtree pull to result in a single squash commit right on my current branch (yet its commit message may definitely detail what central commits it pulled).
  * **Familiar subcommands.**  This is inspired by `git-subtree`'s well-thought-out reuse of familiar semantics such as `push` and `pull`, except here we won't ask you to re-state all your settings again, as we persisted them on `add`.
  * **Ability to select what local updates to backport.** Unlike `git-subtree`, we do not mandate that every commit you've done on your subtree's local code be backported upstream when you `push`: you can specify which commits to backport.
  * **Extra tooling for subtree management.** The `list`, `rm` and `forget` commands are all there to make your subtree management easier.  We also provide a full-featured **Bash completion script** you can run after your regular Git completion.

## Installation

At a minimum, you simply need to put the `git-stree` script somewhere in your PATH (`/usr/local/bin` seems like a good choice), and make sure it has executable permissions (`chmod +x` it if need be).

The script an then automatically be used as either `git-stree` or `git stree` (because Git is cool like that).

If you want the completion (which is always nice), you should the `git-stree-completion.bash` file somewhere and make sure it is loaded, preferrably *after* Git's original completion.  On many Linux systems, this just means putting that file in `/etc/bash_completion.d/`.  Otherwise, just `source` it in your user's shell initialization file (`~/.bashrc`, `~/.bash_profile` or `~/.profile`, depending on your situation), making sure you do so after Git's completion file, so our completion can piggy-back on its system for the main `git` command.

## Usage

Simply use the `git stree` command. If you don't pass it any argument, or use the `help` subcommand or `--help` option, you'll get detailed usage information.

Also note that any subcommand can display its specific usage info much like with Git built-in commands, either by saying `git stree help add` or `git stree add --help`.

## Subcommands

`git stree` has a number of subcommands you use to manage your subtrees with ease.

**Important note:** we will never conflate your ongoing commit work (your stage, basically) with our own manipulations, so most commands will refuse to go ahead if you have an **ongoing stage** (and will explicitly tell you what the problem is).  In the same spirit, as most commands will perform a new commit on the current HEAD and you likely don't want to lose it, they will refuse to work if you're in **detached HEAD** state (again, telling you what the problem is).

### add

```
git stree add <name> -P <prefix> <url> [<branch>]
```

Use this to add a new subtree to your current repo, and do its initial pull.

  * `name` is your subtree's name.  It is used as a basis for the names of the remote, settings section and backport branch.  If you have `iconv` and `tr` available on your system it will get normalized, but you should generally stick to ASCII alphanumeric characters (dashes and underscores are also okay). This is also the name you'll use for most other commands to tell them which subtree you want to manipulate.
  * `prefix` is the subdirectory in which to install your subtree's codebase.  We do not mandate that `add` be used from the root of your repo, so this will get normalized from that root.
  * `url` is the URL for the new remote that will be created for tracking your subtree's central code and backporting to it (if you wish to).  Any valid Git URL will work, including filesystem paths and `file://` URLs.
  * `branch` is the remote branch you want to track with your subtree.  It defaults to `master`.

Example call:

```
$ git stree add logging -P vendor/plugins/logging git@github.com:myorg/plugins-logging.git
[master f01fe86] [STree] Added stree 'logging' in vendor/plugins/logging
 4 files changed, 24 insertions(+)
 create mode 100644 vendor/plugins/logging/README.md
 create mode 100644 vendor/plugins/logging/demo.txt
 create mode 100644 vendor/plugins/logging/lib/index.js
 create mode 100644 vendor/plugins/logging/plugin-config.json

✔︎ STree 'logging' configured, 1st injection committed.
```

### forget

This command removes any setting (including remotes) and backport branches related to subtrees managed by `git stree`.

However, the local code trees remain untouched, as your codebase should still be needing them…

Say you have two subtrees defined already: `logging` and `payment`.  You'd get something like this:

```
$ git stree forget
• Removed subtree 'logging'
• Removed subtree 'payment'
✔︎ Successfully removed all subtree definitions.
```

### list

Not sure what subtrees you have defined in there?  Just ask:

```
$ git stree list
• logging [vendor/plugins/logging] <=> git@github.com:myorg/plugins-logging.git@master
• payment [vendor/plugins/payment] <=> git@github.com:myorg/plugins-payment.git@master
```

You can ask for further details with the `-v` option, which lists the latest sync (pull from the subtree's remote branch) and backport (push you used to send part or all of your local updates for this subtree back to its remote branch):

```
git stree list -v
• logging [vendor/plugins/logging] <=> git@github.com:myorg/plugins-logging.git@master

  Latest sync: dcdb617 - Sun Nov 9 11:50:53 2014 +0100 - [STree] Added stree 'logging' in vendor/plugins/logging (Christophe Porteneuve)

• payment [vendor/plugins/payment] <=> git@github.com:myorg/plugins-payment.git@master (backports through stree-backports-payment)

  Latest sync:     b1b9ed4 - Sun Nov 9 11:55:23 2014 +0100 - Payment general perf fix (Christophe Porteneuve)
  Latest backport: 787bd12 - Sun Nov 9 11:55:23 2014 +0100 - Payment general perf fix (Christophe Porteneuve)
```

### pull

If the central code for your subtree has evolved, mostly due to maintenance and upgrades, and you wish to grab these updates in your local copy, just pull:

```
git stree pull <name>
```

For instance:

```
$ git stree pull logging

[master 1be35a9] [STree] Pulled stree 'logging'
 1 file changed, 1 insertion(+), 1 deletion(-)
✔︎ STree 'logging' pulled, updates committed.
```

The commit message for the pull (which is a squashed commit of all the updates in the remote subtree since your last pull) gives you the details:

```
$ git show -s
commit 1be35a9
Author: Christophe Porteneuve <tdd@tddsworld.com>
Date:   Sun Nov 9 12:10:49 2014 +0100

    [STree] Pulled stree 'logging'

    Squashed commit of the following:

    commit 343ce9aa62275ca328bb7b4ab62d2c25b97d6cc5
    Author: Christophe Porteneuve <tdd@tddsworld.com>
    Date:   Sun Nov 9 12:10:31 2014 +0100

        Better log timestamping
```

### push

The `push` command lets you backport part or all of the local updates you've made on the subtree's code.

```
git stree push <name> [<commit>...]
```

For this to work properly, you need to observe a good hygiene for your commits on your local copy of the subtree: make sure such changes are in their own commits, not mixed up with changes elsewhere in your working directory.

If you wish to backport everything (say that all you did was relevant for everyone using the subtree, not just your own current codebase), just push:

```
$ git stree push payment
• b1b9ed4 Payment general perf fix
✔︎ STree 'payment' successfully backported local changes to its remote
```

We remember your last sync point with the subtree's remote branch, on `add`, `pull` and `push`, so we don't try to backport commits that are known to the remote branch already, or have been explicitly ignored by your prior pushes.

Under the hood, this will create a special backport branch the first time around (and on later pushes, update it first by rebasing it on the subtree's remote branch, auto-stashing any local changes you may have around the rebase to avoid confusion).

Then every eligible commit is cherry-picked, subtree-style, to the backport branch.  When we're done, it's pushed to the subtree's remote branch.  Then we get back to what your HEAD was before the `stree push`.

If you wish to backport only certain commits, just list them (any commit-ish will do: SHAs and abbrevs, branch tips, tags, etc.) after the subtree's name.

This command actually works on a detached HEAD, as it will work on another local branch anyway.

### rm

If you wish to remove a subtree definition (perhaps to add it again a different way) and its artefacts (such as the backport branch), just call this command.  It accepts one subtree name:

```
$ git stree rm payment
✔︎ All settings removed for STree 'payment'.
```

If you wish to remove all subtree settings, use `git stree forget` instead.

## Caveats

  * Completion likely doesn't work on zsh just now, and perhaps not well on msysGit / Cygwin environments.
  * Just like `git-subtree`, we advise strongly you keep local updates to your subtree in their own dedicated commits, to facilitate backporting some of these to the subtree's remote.
  * Subtree settings currently remain local to your repo (in your local Git configuration).  Work is ongoing to provide subcommands facilitating the versioning and sharing of stree setttings.

## Contributing

We welcome all contributions, especially in the following areas:

  * Bugfixes
  * Extended completion (especially zsh compatibility, and Cygwin/msysgit for Windows users)
  * Unit tests

To contribute, just fork this repository on GitHub, write your stuff and send a pull request.

## License

This work is copyright © 2014 Christophe Porteneuve, and MIT-licensed.  See the details in the `LICENSE` file.
