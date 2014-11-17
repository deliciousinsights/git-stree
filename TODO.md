* Code: Fix weird display of single-command help

* Doc: README: A use case or two up front, such as
  "This is best used when you have a X and Y...",
  could help the documentation page provide context
  and discoverability for those new to the subtree concept in general

* Doc/Onboarding: A set of sample repos (for example, we use
  https://github.com/githubtraining/example-dependency to show
  submodules) might be a great way to show the before and after in
  practice. Nothing beats real Git repo history.

* Doc: README: an animated GIF of console typing could help offer
  context to "It uses merges, even in squash mode, which means it
  pollutes the graph with long-running, oft-merged branches for every
  subtree." and "It requires every command to re-specify the entire
  subtree settings (remote URL/name, remote branch, local tree prefix)."
  If not an animated GIF, then a circle-and-line diagram for the first
  and fixed-width text invocation example for the second.

* Code: git stree share, so we dup/sync the config in .gitstrees
* Code: git stree update, so we dup/sync the config from .gitstrees
* Code: Unit tests, perhaps around fast-export-produced repos that are fast-imported ad hoc.
