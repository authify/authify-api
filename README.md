# Authify::API

## Introduction

Authify is a web service built from the ground up to simplify authentication and provide it securely to a collection of related web sites.

Authify borrows heavily from [OAuth](https://en.wikipedia.org/wiki/OAuth) concepts, though keeps things a bit simpler, combining the `authorize` and `token` steps and relying on asymmetric, cryptographic signatures rather than additional fields for verification.

## The Details

The Authify API service consists of a database for storing:

* Users
* User API Keys
* User Identities (such as logins from other services)
* Organizations (and membership)
* Groups (and membership)
* Trusted authify delegates (other services with unlimited capabilities, including impersonating users)

Nearly all API endpoints available via Authify implement the [{json:api}](http://jsonapi.org/) 1.0 specification. The exceptions are:

* `/jwt/key` - Returns Content Type: `application/x-pem-file`. This endpoint returns the PEM-encoded public key ([ES265](https://tools.ietf.org/html/rfc7518#section-3.4) (ECDSA)) which should be used to verify the signature made by the Authify service.
* `/jwt/token` - Returns (and only accepts) Content Type: `application/json`. This endpoint is used to obtain a [JWT token](https://en.wikipedia.org/wiki/JSON_Web_Token) for authentication when interacting with restricted endpoints (both on this service and for other integrated services).

All other endpoints adhere to the {json:api} specification and can be found at the following base paths:

* `/api-keys` - User API keys. Index is restricted. Should only really be useful for users manipulating their own keys.
* `/groups` - Groups. Index is restricted. Most interactions with groups should be scoped via organizations.
* `/identities` - Alternate User Identities. These are other services that the user can login via (web UI only).
* `/organizations` - Organizations. These are high-level groupings of users and groups. Non-administrators should only be able to see limited amounts of information about organizations.
* `/users` - Users controller.

In addition to expiring JWTs provided via `/jwt/token` for normal user interactions, Trusted Delegates can perform any action by providing the `X-Authify-Access`, `X-Authify-Secret`, and the `X-Authify-On-Behalf-Of` headers. The `Access` and `Secret` headers are used to authenticate the remote application, and the `On-Behalf-Of` is used to impersonate the user (usually determined through a process on the remote end to establish the user's identity). These values do not expire and are not easily created or removed. For this reason, they should be used **very** sparingly. They can only be created, listed, or removed via a set of `rake` commands run server-side. These are:

* `rake delegate:add[<name>]` - where `<name>` is the unique name of the trusted delegate. For example, `rake delegate:add[foo]` adds a remote delegate named `foo`. This command will output a key / value set providing the access\_key and secret\_key. The secret\_key is stored as a one-way hash in the DB, so it can never be retrieved again.
* `rake delegate:list` - lists the names of all trusted delegates along with their access keys.
* `rake delegate:remove[<name>]` - where `<name>` is the unique name of the trusted delegate to remove.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'authify-api'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install authify-api

## Usage

## Configuration



## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/knuedge/authify-api.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
