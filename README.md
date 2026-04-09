# bdev

Personal development toolkit for [Claude Code](https://code.claude.com).

## Install

In Claude Code, run:

```
/plugin marketplace add black-desk/bdev
```

This adds the `bdev` marketplace, which provides access to the plugin.

```
/plugin install bdev@bdev
```

And then reload plugins:

```
/reload-plugins
```

That's it. The plugin's skills and agents are now available in your Claude Code
session.

## Verify installation

Run `/plugin` and check the **Installed** tab. You should see `bdev@bdev`
listed.

## Update

To get the latest version:

```
/plugin marketplace update bdev
/plugin install bdev@bdev
/reload-plugins
```

## Uninstall

```
/plugin uninstall bdev@bdev
```
