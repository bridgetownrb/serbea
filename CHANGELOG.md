# Changelog

## 2.2.0

- Add functionality to purge certain `Object`-based method pollution which interferes with the workings of Serbea's `Pipeline` in pure Ruby.
- Ruby 3.1 is now the minimum required version.

## 2.1.0

- Remove Active Support as a dependency
  - This now provides rudimentary support of `html_safe` mechanics. Note that
    it does NOT handle _any_ additional String methods. It simply allows cloning a string via `html_safe` to mark it safe, and `html_safe?` to query if it's safe.
  - This _might_ be a breaking change, but likely not if you're using Serbea along with Rails or Bridgetown. To restore previous functionality manually, just install the `activesupport` gem and `require "active_support/core_ext/string/output_safety"` before you require the Serbea gem.

## 2.0.0

- Add plain ol' Ruby pipeline functionality
- Raise errors using gem-based classes
- Upgrade docs site to Bridgetown 1.3.1 and esbuild

## 1.0.1

- Widespread release.
