pad_service_econfd_mgr
=====

This service is an `econfd` daemon and subscription manager.

* Service prefix: `/econfd/mgr/`

* Subscriptions:

  - __"/econfd/mgr/daemons/add/post"__
    - Payload

      ```json
        '{
          "ip":               str,
          "port":             integer,
          "name":             str,
          "callpoint":        str,
          "callback_module":  str,
          "args":             TBD
        }'
      ```
    You can POST an empty json `{}` to create a default (dummy) econfd daemon named `econfd_daemon_default`.
    The econfd daemon callback must be provided. See `pad_service_econfd_daemon`.

Build
-----

  $ rebar3 compile

Usage
-----

_Pre-requisites:_ ConfD and CloudI up and running

Let's assume our repos are located at `/toplevel`:

```bash
$ cd /toplevel
$ ls
econfd pad_service_econfd_mgr pad_service_econfd_daemon
```

*Use `cloudit` to manage services.*

Set toplevel directory (root dir for all project repos).

```python
cloudit.set_cwd("/toplevel")
```

Add code paths:

```python
cloudit.code_path_add('pad_service_econfd_mgr')
cloudit.code_path_add('pad_service_econfd_daemon')
cloudit.code_path_add('/toplevel/pad_service_econfd_mgr/_build/default/lib/econfd/ebin')
```

Add service:

```python
cloudit.service_add('pad_service_econfd_mgr')
```

See `pad_service_econfd_daemon` README file.

Make a `post` to add a new econfd daemon (depends on *pad_service_econfd_daemon* service)

```python
cloudit.post("econfd/mgr/daemons/add")
```
