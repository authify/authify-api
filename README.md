# Authify::API

[![Gem Version](https://badge.fury.io/rb/authify-api.svg)](https://badge.fury.io/rb/authify-api)
[![Build Status](https://travis-ci.org/knuedge/authify-api.svg?branch=master)](https://travis-ci.org/knuedge/authify-api)
[![Coverage Status](https://coveralls.io/repos/github/knuedge/authify-api/badge.svg?branch=master)](https://coveralls.io/github/knuedge/authify-api?branch=master)

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

Nearly all API endpoints available via Authify implement the [{json:api}](http://jsonapi.org/) 1.0 specification, though there are a few exceptions.

### Non-standard API Endpoints

**`GET /jwt/key`**
_Returns Content Type: `application/json`._

This endpoint returns a JSON Object with the key `data` whose value is a PEM-encoded ECDSA public key, which should be used to verify the signature made by the Authify service.

**`GET /jwt/meta`**
_Returns Content Type: `application/json`._

This endpoint returns a JSON Object with the keys `algorithm`, `issuer`, and `expiration` that describe the kind of JWTs produced by this service.

**`POST /jwt/token`**
_Returns (and only accepts) Content Type: `application/json`._

This endpoint is used to obtain a [JWT](https://en.wikipedia.org/wiki/JSON_Web_Token). This endpoint expects a JSON Object with either the keys `access_key` and `secret_key` _OR_ `email` and `password`. There is no firm requirement to use either pair for any particular purpose, but for scenarios where the credentials may be stored, the `access_key` and `secret_key` can easily be revoked if necessary.

Upon successful authentication, the endpoint provides a JSON Object with the key `jwt` and a signed JWT. There should be nothing highly sensitive embedded in the JWT. The JWT defaults to expiring every 15 minutes.

This endpoint also allows optionally specifying a key called `inject` with a JSON object as a value. This JSON object will then be injected into a top-level `custom` key in the returned JWT _as is_.

**`GET/POST /jwt/verify`**
_Returns (and only accepts) Content Type: `application/json`_

This endpoint is useful for debugging or for low-volume, simple clients. Pass either a `GET` parameter of `token` or `POST` a JSON object with the key `token`. In either case, the value is a JWT that can be validated and have its details returned as simple JSON data.

For valid JWTs, this endpoint will return a JSON object with the keys `valid`, `payload`, `type`, and `algorithm`. The `valid` field is a boolean that describes whether or not the JWT is valid for use with this instance of Authify. The `payload` field is the full JWT payload, with all its claims listed as keys in a JSON object. The `type` key should always return `JWT` but is reserved for future use. Finally, the `algorithm` key describes the JWA algorithm used to sign the key. See the [configuration section](#configuration) for details on the algorithm.

For invalid or expired JWTs, this endpoint will still return `200 OK`, so don't rely on that to determine if the JWT is valid. It will, however, return different data. In this case, the endpoint will respond with a JSON object with the keys `valid`, `errors`, and `reason`. For invalid JWTs, the `valid` boolean will be `false`. The `errors` key will be a list of errors encountered while processing the JWT. The `reason` key provides a simple and generic explanation of the first encountered failure.

**`POST /registration/signup`**
_Returns (and only accepts) Content Type: `application/json`._

This endpoint is used to signup for an account with Authify. This endpoint expects a JSON Object, requiring the keys `email` and `password`, with `name` and `via` being optional. If `via` is provided, then it must be a JSON Object with the keys `provider` and `uid`, otherwise it will be ignored. The `via` key is used to add an alternate identity (meaning they logged-in through an integration, like Github), and is only trusted from trusted delegates (meaning it will be ignored for anonymous calls to this endpoint).

This endpoint returns a JSON Object with the keys `id`, `email`, and `verified`, on success. If the user is registered by a trusted delegate *and* `via` options were provided, the users is implicitly trusted and a `jwt` key will also be provided for authentication. Otherwise, users will need to proceed to `/registration/verify` with the token they receive by email to verify their identity.

This endpoint allows customization of the emails sent for users requiring verification. For information on how this works, see the [Templating](#templating) section. The following template expressions are available: `token` and `valid_until`.

**`POST /registration/verify`**
_Returns (and only accepts) Content Type: `application/json`._

This endpoint is used to verify a registered user's email address. Currently, the data used to verify users is a token provided via email.

This endpoint expects a JSON Object, requiring the keys `email`, `password`, and `token`. This endpoint returns a JSON Object with the keys `id`, `email`, `verified`, and `jwt` on success.

**`POST /registration/forgot_password`**
_Returns (and only accepts) Content Type: `application/json`._

This endpoint serves two related purposes: it is used to trigger resetting a forgotten (or non-existent) password and it is used to actually set the value of a user's password. The difference in which operation is performed is based on the POST data.

When provided a JSON Object with only the key `email`, the endpoint sends the user an email with a verification token, returning an empty JSON Object as a result. When provided a JSON Object with the keys `email`, `password`, and `token`, the endpoint verifies that the token matches, then sets the user's password, returning a JSON Object with the keys `id`, `email`, `verified`, and `jwt` on success.

This endpoint allows customization of the emails sent for users requiring verification. For information on how this works, see the [Templating](#templating) section. The following template expressions are available: `token` and `valid_until`.

### {json:api} API Endpoints

All other endpoints adhere to the {json:api} specification and can be found at the following base paths:

**`/apikeys`**
User API keys. Index is restricted. Should only really be useful for users manipulating their own keys.

**`/groups`**
Groups. Index is restricted. Most interactions with groups should be scoped via organizations.

**`/identities`**
Alternate User Identities. These are other services that the user can login via (web UI only).

**`/organizations`**
Organizations. These are high-level groupings of users and groups. Non-administrators should only be able to see limited amounts of information about organizations.

**`/trusted-delegates`**
Trusted Delegates. These are heavily-integrated applications that can offload some of the API's functionality (usually getting a user's credentials). All actions on this controller require `admin` access to Authify. See [Trusted Delegates](#trusted_delegates) below for more info.

**`/users`**
Users controller.

### Trusted Delegates

In addition to expiring JWTs provided via `/jwt/token` for normal user interactions, Trusted Delegates can perform any action by providing the `X-Authify-Access`, `X-Authify-Secret`, and the `X-Authify-On-Behalf-Of` headers. The `Access` and `Secret` headers are used to authenticate the remote application, and the `On-Behalf-Of` is used to impersonate the user (determined through a process on the remote, trusted delegate's end to establish the user's identity).

Note that while these sound similar to User API keys, these Trusted Delegate credentials are longer and can not be interchanged with User API Keys. These values do not expire and are not easily created or removed. For this reason, they should be used **very** sparingly. In a pinch, they can be created, listed, or removed via a set of `rake` commands run server-side. These are:

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

## Configuration

The Authify API services supports the following configuration settings, managed via environment variables of the same name:

**`AUTHIFY_DB_URL`**
The URL used by [ActiveRecord](http://guides.rubyonrails.org/configuring.html#configuring-a-database) to connect to the database. Currently supports `mysql2://` or `sqlite3://` URLs, though any driver supported by ActiveRecord should work if the required gems are installed. Defaults to `mysql2://root@localhost:3306/authifydb`.

**`AUTHIFY_PUBKEY_PATH`**
The path on the filesystem to the PEM-encoded, public ECDSA key. Defaults to `~/.authify/ssl/public.pem`.

**`AUTHIFY_PRIVKEY_PATH`**
The path on the filesystem to the PEM-encoded, private ECDSA key. Currently, Authify only supports an [ECDSA](https://en.wikipedia.org/wiki/Elliptic_Curve_Digital_Signature_Algorithm) keys. Options include using a `secp521r1` curve and the [SHA-512](https://en.wikipedia.org/wiki/SHA-2) hashing algorithm (called `ES512`), a `secp384r1` curve and the SHA-384 hashing algorithm (called `ES384`), or a `prime256v1` curve and the SHA-256 hashing algorithm (called `ES256`). See `AUTHIFY_JWT_ALGORITHM` below for information on how to configure Authify's algorithm to match the public and private keys you provide. The keys you specify **must** match the ECDSA algortihm and curve used to create them.

**`AUTHIFY_JWT_ISSUER`**
The name of the issuer ([iss field](https://en.wikipedia.org/wiki/JSON_Web_Token#Standard_fields)) used when creating the JWT. This **must** match on any service that verifies the JWT (meaning any service relying on Authify for authentication), and it **must** be the same for all services that integrate with Authify.

**`AUTHIFY_JWT_ALGORITHM`**
The name of the [JWA](https://tools.ietf.org/html/draft-ietf-jose-json-web-algorithms-40) algorithm to use when loading keys and creating or verifying JWT signatures. Valid values are `ES256`, `ES384`, or `ES512`. Defaults to `ES512`. This **must** match the curve and algorithm used to produce the public and private keys found at `AUTHIFY_PUBKEY_PATH` and `AUTHIFY_PRIVKEY_PATH`, respectively. Note that the curves `prime256v1` (also called NIST P-256) used by `ES256` and `secp384r1` (also called NIST P-384) used by `ES384`, while offering a wider range of compatible SSL libraries, are described as unsafe on [SafeCurves](https://safecurves.cr.yp.to/) for several reasons described there.

**`AUTHIFY_JWT_EXPIRATION`**
How long should a JWT be valid (in minutes). Defaults to 15. Too small of a value will mean a lot more requests to the API; too high increases the possibility of viable keys being captured.

**`AUTHIFY_VERIFICATIONS_REQUIRED`**
Allows disabling the requirement for email verifications for user signups. **NOT RECOMMENDED FOR PRODUCTION!** This should be used only if public signups are disabled (which is not yet implemented) or for integration testing. Simply set this environment variable to `'false'` (as a string) and Authify will not enforce verifications (making them optional).

## Usage and Authentication Workflow

### Generating an SSL Certificate

Here is an example in Ruby for generating an SSL cert for use with the Authify API server:

```ruby
require 'openssl'
# Using ES512. For others, switch 'secp512r1' to the desired curve
secret_key = OpenSSL::PKey::EC.new('secp521r1')
secret_key.generate_key
# write out the private key to a file...
File.write(File.expand_path('/path/to/keys/private.pem'), secret_key.to_pem)
public_key = secret_key
public_key.private_key = nil
# write out the public key to a file...
File.write(File.expand_path('/path/to/keys/public.pem'), public_key.to_pem)
```

Using the OpenSSL CLI tool:

```shell
# Private key
openssl ecparam -name secp521r1 -genkey -out /path/to/keys/private.pem
# Public key
openssl ec -in /path/to/keys/private.pem -pubout -out /path/to/keys/public.pem
```

### Authenticating for API clients

We'll show how to interact with the API using `curl` as an example, and we'll assume the server is running at `auth.mycompany.com`.

#### Register a new user

```shell
curl \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  --data \
  '{
    "name": "Some User",
    "email": "someuser@mycompany.com",
    "password": "b@d!dea"
  }' \
  https://auth.mycompany.com/registration/signup
```

This will return JSON similar to the following:

```javascript
{
  "id": 172,
  "email": "someuser@mycompany.com",
  "verified": false
}
```

As you can see, Authify is stating that while you have registered a user, their email address has not been verified. They should receive an email containing a one-time verification token, valid for an hour. Verify the email by POSTing something similar to:

```shell
curl \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  --data \
  '{
    "email": "someuser@mycompany.com",
    "password": "b@d!dea",
    "token": "c7994995c89039ab"
  }' \
  https://auth.mycompany.com/registration/verify
```

This will return JSON similar to the following:

```javascript
{
  "id": 172,
  "email": "someuser@mycompany.com",
  "verified": true,
  "jwt": "eyJ0eXAiOiJKV1QiLCJhbGciOiJFUzUxMiJ9.eyJleHAiOjE0ODY0ODcyODcsImlhdCI6MTQ4NjQ4MzY4NywiaXNzIjoiTXkgQXdlc29tZSBDb21wYW55IEluYy4iLCJzY29wZXMiOlsidXNlcl9hY2Nlc3MiXSwidXNlciI6eyJ1c2VybmFtZSI6ImZvb0BiYXIuY29tIiwidWlkIjoyLCJvcmdhbml6YXRpb25zIjpbXSwiZ3JvdXBzIjpbXX19.AWfPpKX9mP03Djz3-LMneJdEVsXQm_4GOPVCdkfiiBeIR4pVLKTVrNoNdlNgSEkZEeUw1RPsVxpAR7wDgB4cNcYiAP3fNaD8OPyWfOQAV0lTvDUSH3YU39cZAVwvbX9HleOHBLrFGBbui5wSvfi7WZZlH808psiuUAVhBOe7mfrNiHGB"
}
```

The user is now verified. You'll need the JWT (found at key `jwt`) for the next step.

#### Create an API key set

```shell
curl \
  -H 'Content-Type: application/vnd.api+json' \
  -H 'Accept: application/vnd.api+json' \
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJFUzUxMiJ9.eyJleHAiOjE0ODY0ODcyODcsImlhdCI6MTQ4NjQ4MzY4NywiaXNzIjoiTXkgQXdlc29tZSBDb21wYW55IEluYy4iLCJzY29wZXMiOlsidXNlcl9hY2Nlc3MiXSwidXNlciI6eyJ1c2VybmFtZSI6ImZvb0BiYXIuY29tIiwidWlkIjoyLCJvcmdhbml6YXRpb25zIjpbXSwiZ3JvdXBzIjpbXX19.AWfPpKX9mP03Djz3-LMneJdEVsXQm_4GOPVCdkfiiBeIR4pVLKTVrNoNdlNgSEkZEeUw1RPsVxpAR7wDgB4cNcYiAP3fNaD8OPyWfOQAV0lTvDUSH3YU39cZAVwvbX9HleOHBLrFGBbui5wSvfi7WZZlH808psiuUAVhBOe7mfrNiHGB" \
  --data \
  '{
    "data":
    {
      "type": "apikeys"
    }
  }' \
  https://auth.mycompany.com/apikeys
```

This endpoint (as can be seen from the `Accept` and `Content-Type` headers) speaks only {json:api} and will return something like this with an HTTP 201:

```javascript
{
  "data": {
    "type": "apikeys",
    "id": "197",
    "attributes": {
      "access-key": "4bb651af1754b2dff5b9",
      "secret-key": "a3f1ee5085dad87d53ce04a1857a2677c7ffa136c506e8174fef6fa1c962e46f",
      "created-at": "2017-02-13 22:50:44 UTC"
    },
    "links": {
      "self": "/apikeys/197"
    },
    "relationships": {
      "user": {
        "links": {
          "self": "/apikeys/197/relationships/user",
          "related": "/apikeys/197/user"
        }
      }
    }
  },
  "jsonapi": {
    "version": "1.0"
  },
  "included": [

  ]
}
```

Note that **it will not be possible to retrieve the `secret-key` attribute in plaintext again**, so store the results in a safe place.

#### Obtain a JWT

```shell
curl \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  --data \
  '{
    "access_key": "5f4abd1c6423ef02d1ec42e1cddaf5f8",
    "secret_key": "fb97aa7d4e48f3e4bbb2930161a423fa8308393426c3612940da03f22cf36879"
   }' \
  https://auth.mycompany.com/jwt/token
```

Note that you can also use either the underscored format for logging in with API keys (`access_key` and `secret_key`) or the dashed version provided in the {json:api} response before (`access-key` and `secret-key`). For all other endpoints (those adhering to the {json:api} spec) the dashed approach is required.

The server will return something like:

```javascript
{"jwt":"eyJ0eXAiOiJKV1QiLCJhbGciOiJFUzUxMiJ9.eyJleHAiOjE0ODY0ODcyODcsImlhdCI6MTQ4NjQ4MzY4NywiaXNzIjoiTXkgQXdlc29tZSBDb21wYW55IEluYy4iLCJzY29wZXMiOlsidXNlcl9hY2Nlc3MiXSwidXNlciI6eyJ1c2VybmFtZSI6ImZvb0BiYXIuY29tIiwidWlkIjoyLCJvcmdhbml6YXRpb25zIjpbXSwiZ3JvdXBzIjpbXX19.AWfPpKX9mP03Djz3-LMneJdEVsXQm_4GOPVCdkfiiBeIR4pVLKTVrNoNdlNgSEkZEeUw1RPsVxpAR7wDgB4cNcYiAP3fNaD8OPyWfOQAV0lTvDUSH3YU39cZAVwvbX9HleOHBLrFGBbui5wSvfi7WZZlH808psiuUAVhBOe7mfrNiHGB"}
```

You can also request that the server inject some custom payload data into the JWT:

```shell
curl \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  --data \
  '{
    "access_key": "5f4abd1c6423ef02d1ec42e1cddaf5f8",
    "secret_key": "fb97aa7d4e48f3e4bbb2930161a423fa8308393426c3612940da03f22cf36879",
    "inject": {
      "foo": "bar"
    }
   }' \
  https://auth.mycompany.com/jwt/token
```

This can be useful for loosely coupling services that need to exchange small amounts of (preferably encrypted) data. This data is arbitrary and Authify does nothing to validate it. It simply injects it into the payload before it is signed, so don't assume nefarious users can't spoof things. You'll likely need to do something to make the data verifiable on the receiving end.

#### Use the JWT to Access a Protected Resource

```shell
curl \
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJFUzUxMiJ9.eyJleHAiOjE0ODY0ODcyODcsImlhdCI6MTQ4NjQ4MzY4NywiaXNzIjoiTXkgQXdlc29tZSBDb21wYW55IEluYy4iLCJzY29wZXMiOlsidXNlcl9hY2Nlc3MiXSwidXNlciI6eyJ1c2VybmFtZSI6ImZvb0BiYXIuY29tIiwidWlkIjoyLCJvcmdhbml6YXRpb25zIjpbXSwiZ3JvdXBzIjpbXX19.AWfPpKX9mP03Djz3-LMneJdEVsXQm_4GOPVCdkfiiBeIR4pVLKTVrNoNdlNgSEkZEeUw1RPsVxpAR7wDgB4cNcYiAP3fNaD8OPyWfOQAV0lTvDUSH3YU39cZAVwvbX9HleOHBLrFGBbui5wSvfi7WZZlH808psiuUAVhBOe7mfrNiHGB" \
  -H 'Accept: application/vnd.api+json' \
  https://auth.mycompany.com/organizations
```

### Templating

Some endpoints support custom templates (and other customizations) for communications sent out to users. This is most useful for services that integrate with Authify but wrap that integration in their own UI.

If an endpoint declares that it supports templating (such as `/registration/signup`), what this means is that the JSON `POST` data can include an optional `templates` key. To customize the plaintext email body and subject, you can change a `POST` from something like this:

```javascript
{
  "name": "Some User",
  "email": "someuser@mycompany.com",
  "password": "b@d!dea"
}
```

to include a `templates` section like this:

```javascript
{
  "name": "Some User",
  "email": "someuser@mycompany.com",
  "password": "b@d!dea",
  "templates": {
    "email": {
      "body": "Your code is: '{{token}}' and it is valid until {{valid_until}}.",
      "subject": "Verification Code"
    }
  }
}
```

Authify's templating supports something that looks a bit like [Handlebars](http://handlebarsjs.com/) templating (though it doesn't yet support most of the Handlebars features). This is useful for allowing the injection of dynamic data into your templates. Available expressions should be declared in the README section that describes a template-capable endpoint.

For some template data, escaping can be difficult or inconvenient. For these situations, Authify supports optional [Base64](https://en.wikipedia.org/wiki/Base64) encoding of values. To provide a Base64-encoded value, just declare it as such using `{base64}` followed by the data:

```javascript
{
  "name": "Some User",
  "email": "someuser@mycompany.com",
  "password": "b@d!dea",
  "templates": {
    "email": {
      "body": "{base64}WW91ciBjb2RlIGlzOiAne3t0b2tlbn19JyBhbmQgaXQgaXMgdmFsaWQgdW50aWwge3t2YWxpZF91bnRpbH19Lg==",
      "subject": "Verification Code"
    }
  }
}
```

Encoded template data still supports the Handlebars-style templating, but it must be applied _before_ the content is Base64-encoded.

#### Template Types

Currently, only email communications can be templated. The following keys are available for email templates:

```javascript
"templates": {
  "email": {
    "subject": "The subject of the email",
    "body": "The plaintext body of the email",
    "html_body": "<p>An <a href=\"https://en.wikipedia.org/wiki/HTML\">HTML</a> body.</p>"
  }
}
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/knuedge/authify-api.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
