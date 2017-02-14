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

* `GET /jwt/key` - Returns Content Type: `application/json`. This endpoint returns a JSON Object with the key `data` whose value is a PEM-encoded ECDSA public key, which should be used to verify the signature made by the Authify service.
* `GET /jwt/meta` - Returns Content Type: `application/json`. This endpoint returns a JSON Object with the keys `algorithm`, `issuer`, and `expiration` that describe the kind of JWTs produced by this service.
* `POST /jwt/token` - Returns (and only accepts) Content Type: `application/json`. This endpoint is used to obtain a [JWT token](https://en.wikipedia.org/wiki/JSON_Web_Token). This endpoint expects a JSON Object with either the keys `access_key` and `secret_key` _OR_ `email` and `password`. There is no firm requirement to use either pair for any particular purpose, but for scenarios where the credentials may be stored, the `access_key` and `secret_key` may be used since those can easily be revoked if necessary. Upon successful authentication, the endpoint provides a JSON Object with the key `jwt` and a signed JWT. There should be nothing highly sensitive embedded in the JWT. The JWT defaults to expiring every 15 minutes.
* `POST /registration/signup` - Returns (and only accepts) Content Type: `application/json`. This endpoint is used to signup for an account with Authify. This endpoint expects a JSON Object, requiring the keys `email` and `password`, with `name` and `via` being optional. If `via` is provided, then it must be a JSON Object with the keys `provider` and `uid`, otherwise it will be ignored. The `via` key is used to add an alternate identity (meaning they logged-in through an integration, like Github). This endpoint returns a JSON Object with the keys `id`, `email`, and `jwt` on success.

All other endpoints adhere to the {json:api} specification and can be found at the following base paths:

* `/apikeys` - User API keys. Index is restricted. Should only really be useful for users manipulating their own keys.
* `/groups` - Groups. Index is restricted. Most interactions with groups should be scoped via organizations.
* `/identities` - Alternate User Identities. These are other services that the user can login via (web UI only).
* `/organizations` - Organizations. These are high-level groupings of users and groups. Non-administrators should only be able to see limited amounts of information about organizations.
* `/users` - Users controller.

In addition to expiring JWTs provided via `/jwt/token` for normal user interactions, Trusted Delegates can perform any action by providing the `X-Authify-Access`, `X-Authify-Secret`, and the `X-Authify-On-Behalf-Of` headers. The `Access` and `Secret` headers are used to authenticate the remote application, and the `On-Behalf-Of` is used to impersonate the user (usually determined through a process on the remote end to establish the user's identity). Note that while these sound similar to User API keys, these Trusted Delegate credentials are longer and can not be interchanged. These values do not expire and are not easily created or removed. For this reason, they should be used **very** sparingly. They can only be created, listed, or removed via a set of `rake` commands run server-side. These are:

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

* `AUTHIFY_DB_URL` - The URL used by [ActiveRecord](http://guides.rubyonrails.org/configuring.html#configuring-a-database) to connect to the database. Currently supports `mysql2://` or `sqlite3://` URLs, though any driver supported by ActiveRecord should work if the required gems are installed. Defaults to `mysql2://root@localhost:3306/authifydb`.
* `AUTHIFY_PUBKEY_PATH` - The path on the filesystem to the PEM-encoded, public ECDSA key. Defaults to `~/.authify/ssl/public.pem`.
* `AUTHIFY_PRIVKEY_PATH` - The path on the filesystem to the PEM-encoded, private ECDSA key. Currently, Authify only supports an [ECDSA](https://en.wikipedia.org/wiki/Elliptic_Curve_Digital_Signature_Algorithm) keys. Options include using a `secp521r1` curve and the [SHA-512](https://en.wikipedia.org/wiki/SHA-2) hashing algorithm (called `ES512`), a `secp384r1` curve and the SHA-384 hashing algorithm (called `ES384`), or a `prime256v1` curve and the SHA-256 hashing algorithm (called `ES256`). See `AUTHIFY_JWT_ALGORITHM` below for information on how to configure Authify's algorithm to match the public and private keys you provide. The keys you specify **must** match the ECDSA algortihm and curve used to create them. 
* `AUTHIFY_JWT_ISSUER` - The name of the issuer ([iss field](https://en.wikipedia.org/wiki/JSON_Web_Token#Standard_fields)) used when creating the JWT. This **must** match on any service that verifies the JWT (meaning any service relying on Authify for authentication), and it **must** be the same for all services that integrate with Authify.
* `AUTHIFY_JWT_ALGORITHM` - The name of the [JWA](https://tools.ietf.org/html/draft-ietf-jose-json-web-algorithms-40) algorithm to use when loading keys and creating or verifying JWT signatures. Valid values are `ES256`, `ES384`, or `ES512`. Defaults to `ES512`. This **must** match the curve and algorithm used to produce the public and private keys found at `AUTHIFY_PUBKEY_PATH` and `AUTHIFY_PRIVKEY_PATH`, respectively. Note that the curves `prime256v1` (also called NIST P-256) used by `ES256` and `secp384r1` (also called NIST P-384) used by `ES384`, while offering a wider range of compatible SSL libraries, are described as unsafe on [SafeCurves](https://safecurves.cr.yp.to/) for several reasons described there.
* `AUTHIFY_JWT_EXPIRATION` - How long should a JWT be valid (in minutes). Defaults to 15. Too small of a value will mean a lot more requests to the API; too high increases the possibility of viable keys being captured.

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
File.write(File.expand_path('/path/to/keys/public.pem'), private_key.to_pem)
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
    "password": "b@d!dea",
    "via": {
      "provider": "github",
      "uid": "user1234"
    }
  }' \
  https://auth.mycompany.com/registration/signup
```

This will return JSON similar to the following:

```javascript
{
  "id": 172,
  "email": "someuser@mycompany.com",
  "jwt": "eyJ0eXAiOiJKV1QiLCJhbGciOiJFUzUxMiJ9.eyJleHAiOjE0ODY0ODcyODcsImlhdCI6MTQ4NjQ4MzY4NywiaXNzIjoiTXkgQXdlc29tZSBDb21wYW55IEluYy4iLCJzY29wZXMiOlsidXNlcl9hY2Nlc3MiXSwidXNlciI6eyJ1c2VybmFtZSI6ImZvb0BiYXIuY29tIiwidWlkIjoyLCJvcmdhbml6YXRpb25zIjpbXSwiZ3JvdXBzIjpbXX19.AWfPpKX9mP03Djz3-LMneJdEVsXQm_4GOPVCdkfiiBeIR4pVLKTVrNoNdlNgSEkZEeUw1RPsVxpAR7wDgB4cNcYiAP3fNaD8OPyWfOQAV0lTvDUSH3YU39cZAVwvbX9HleOHBLrFGBbui5wSvfi7WZZlH808psiuUAVhBOe7mfrNiHGB"
}
```

You'll need the JWT (found at key `jwt`) for the next step.

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
    "type": "api-keys",
    "id": "197",
    "attributes": {
      "access-key": "4bb651af1754b2dff5b9",
      "secret-key": "a3f1ee5085dad87d53ce04a1857a2677c7ffa136c506e8174fef6fa1c962e46f",
      "created-at": "2017-02-13 22:50:44 UTC"
    },
    "links": {
      "self": "/api-keys/197"
    },
    "relationships": {
      "user": {
        "links": {
          "self": "/api-keys/197/relationships/user",
          "related": "/api-keys/197/user"
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

The server will return something like:

```javascript
{"jwt":"eyJ0eXAiOiJKV1QiLCJhbGciOiJFUzUxMiJ9.eyJleHAiOjE0ODY0ODcyODcsImlhdCI6MTQ4NjQ4MzY4NywiaXNzIjoiTXkgQXdlc29tZSBDb21wYW55IEluYy4iLCJzY29wZXMiOlsidXNlcl9hY2Nlc3MiXSwidXNlciI6eyJ1c2VybmFtZSI6ImZvb0BiYXIuY29tIiwidWlkIjoyLCJvcmdhbml6YXRpb25zIjpbXSwiZ3JvdXBzIjpbXX19.AWfPpKX9mP03Djz3-LMneJdEVsXQm_4GOPVCdkfiiBeIR4pVLKTVrNoNdlNgSEkZEeUw1RPsVxpAR7wDgB4cNcYiAP3fNaD8OPyWfOQAV0lTvDUSH3YU39cZAVwvbX9HleOHBLrFGBbui5wSvfi7WZZlH808psiuUAVhBOe7mfrNiHGB"}
```

#### Use the JWT to Access a Protected Resource

```shell
curl \
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJFUzUxMiJ9.eyJleHAiOjE0ODY0ODcyODcsImlhdCI6MTQ4NjQ4MzY4NywiaXNzIjoiTXkgQXdlc29tZSBDb21wYW55IEluYy4iLCJzY29wZXMiOlsidXNlcl9hY2Nlc3MiXSwidXNlciI6eyJ1c2VybmFtZSI6ImZvb0BiYXIuY29tIiwidWlkIjoyLCJvcmdhbml6YXRpb25zIjpbXSwiZ3JvdXBzIjpbXX19.AWfPpKX9mP03Djz3-LMneJdEVsXQm_4GOPVCdkfiiBeIR4pVLKTVrNoNdlNgSEkZEeUw1RPsVxpAR7wDgB4cNcYiAP3fNaD8OPyWfOQAV0lTvDUSH3YU39cZAVwvbX9HleOHBLrFGBbui5wSvfi7WZZlH808psiuUAVhBOe7mfrNiHGB" \
  -H 'Accept: application/vnd.api+json' \
  https://auth.mycompany.com/organizations
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/knuedge/authify-api.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
