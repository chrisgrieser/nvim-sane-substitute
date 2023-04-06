# nvim-alt-substitute
A substitute of vim's ":substitute" Ex-command that uses lua (or glob) patterns of vim regex. Supports incremental preview and ranges.

<!-- vale Microsoft.Adverbs = NO --><!-- vale RedHat.Contractions = NO -->
Since you really don't want to learn a whole new flavor of regex, *just* to be able to make search-and-replace operations in your editor.

<!--toc:start-->
- [Motivation](#motivation)
- [Features](#features)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Current Limitations](#current-limitations)
- [Add Support for more Regex Flavors](#add-support-for-more-regex-flavors)
- [Other Search-and-Replace Plugins](#other-search-and-replace-plugins)
- [Credits](#credits)
<!--toc:end-->

## Motivation
<!-- vale Google.FirstPerson = NO -->
Many people like me have only started (neo)vim after the introduction of lua of configuration language. While pretty much everything about neovim can be done with lua by now, search-and-replace-operations `:substitute` are one of few areas remaining where you still have to use vimscript. 

Regardless whether you like vimscript or not, learning vim's flavor of regex *just* for search-and-replace-operations feels somewhat unproductive. So why not work with a regex flavor you are already familiar with? Command of lua patterns is certainly a more transferrable skill than mastering vim regex. Also, lua support comes basically for free without dependencies bundled with neovim already.

While lua patterns are indeed lacking, compared to "real" regex, they do come with a few quite flexible items like [the balanced match `%bxy` or the frontier pattern[^1] `%f[set]`](https://www.lua.org/manual/5.4/manual.html#6.4.1). 

## Features
- Use `:AltSubstitute` or the short form `:S` to do perform search-and-replace
  operations, in lua patterns or javascript regex.
- Incremental preview of the substitution.
- Supports ranges
- The `g` flag is supported and works like with `:substitute`. 
- Extensibility: Support for more flavors is easy to add. [Pull Requests adding more regex flavors are welcome.](#add-support-for-more-regex-flavors)

```lua
:%s /\(\w\+\)\d\+/\1/g          -- :substitute
:S /(%w+)%d+/%1/g               -- nvim-alt-substitute 
deviceModel2020 -> deviceModel  -- result
```

## Installation

```lua
-- lazy.nvim
{
	"chrisgrieser/nvim-alt-substitute",
	cmd = {"S", "AltSubstitute"},
  opts = true,
},

-- packer
use {
	"chrisgrieser/nvim-alt-substitute",
	config = function() require("alt-substitute").setup({}) end,
}
```

## Configuration

```lua
-- default values
opts = {
	regexFlavor = "lua", -- currently: lua|glob
	showNotification = true, -- whether to show the "x replacements made" notification
}
```

Note that any regex flavor other than `lua` requires the respective language support to be installed on your machine. `javascript`, for instance, requires `node`.

## Usage
The `:AltSubstitute` works mostly like `:substitute`.
- The `g` flag works the same way as `:substitute`: Without the `g` flag, only the first match in a line is replaced. With it, every occurrence in a line is replaced.
- Ranges are line-based and work [like all other vim command](https://neovim.io/doc/user/cmdline.html#cmdline-ranges). However, as opposed to `:substitute`, `:AltSubstitute` works on the whole buffer when no range is given. (In other words, `%` is the default range.)
- Like with `:substitute`, slashes (`/`) delimit search query, replace
  value, and flags. Therefore, to search for or replace a `/` you need to escape it with a backslash: `\/`. This applies even if the regex flavor uses a different character for escaping (like the `%` in lua).

## Current Limitations
- Flags other than `g` flag are not supported.
- `inccommand=split` is not supported, Please use `inccommand=unsplit` instead.
- Line breaks in the search or the replacement value are not supported.

## Add Support for more Regex Flavors
The plugin has been specifically built with extensibility in mind. Adding more flavors basically requires bridging one search and one replace function. (Though a certain amount of escaping and performance considerations may be required.) If you want to add support for more languages, have a look this plugin's [regex module](./lua/alt-substitute/regex/), which includes the implementations for lua and glob patterns.

## Other Search-and-Replace Plugins
- [nvim-spectre](https://github.com/windwp/nvim-spectre)
- [serch-replace.nvim](https://github.com/roobert/search-replace.nvim)
- [replacer.nvim](https://github.com/gabrielpoca/replacer.nvim)
- [nvim-search-and-replace](https://github.com/s1n7ax/nvim-search-and-replace)

## Credits
<!-- vale Google.FirstPerson = NO -->
__About Me__  
In my day job, I am a sociologist studying the social mechanisms underlying the digital economy. For my PhD project, I investigate the governance of the app economy and how software ecosystems manage the tension between innovation and compatibility. If you are interested in this subject, feel free to get in touch.

__Profiles__  
- [reddit](https://www.reddit.com/user/pseudometapseudo)
- [Discord](https://discordapp.com/users/462774483044794368/)
- [Academic Website](https://chris-grieser.de/)
- [Twitter](https://twitter.com/pseudo_meta)
- [ResearchGate](https://www.researchgate.net/profile/Christopher-Grieser)
- [LinkedIn](https://www.linkedin.com/in/christopher-grieser-ba693b17a/)

__Buy Me a Coffee__  
<br>
<a href='https://ko-fi.com/Y8Y86SQ91' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://cdn.ko-fi.com/cdn/kofi1.png?v=3' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>

[^1]: Frontier patterns are not mentioned in [neovim's respective section for lua patterns](https://neovim.io/doc/user/luaref.html#luaref-patterns). This is likely due to neovim using LuaJit, which itself is based on Lua 5.1, where [frontier patterns were still an undocumented feature](http://lua-users.org/lists/lua-l/2006-12/msg00536.html). But since they are [officially documented in recent lua version](https://www.lua.org/manual/5.4/manual.html#6.4.1), it should be safe to assume that they are here to stay, so using them should not be an issue.
