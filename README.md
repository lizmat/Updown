[![Actions Status](https://github.com/lizmat/Updown/workflows/test/badge.svg)](https://github.com/lizmat/Updown/actions)

NAME
====

Updown - provide basic API to Updown.io

SYNOPSIS
========

```raku
use Updown;

my $ud = Updown.new;  # assume API key in UPDOWN_API_KEY

my $ud = Updown.new(api-key => "secret-api-key");

for $ud.checks -> (:key($check-id), :value($check)) {
    say "$check.apdex_t() $check.url()"
}

my $event = Updown::Event(%hash);  # inside a webhook
```

DESCRIPTION
===========

Updown provides a simple object-oriented interface to the API as provided by [Updown.io](Updown.io), a website monitoring service.

Access to functionality is provided through the `Updown` class, which has methods that perform the various functions and return objects in the `Updown::` hierarchy of classes.

The [Updown API](https://updown.io/api) is basically followed to the letter, with a little caching and some minor functional sugar added.

To be consistent with the names used in the API, all identifiers use underscores (snake_case) in their names, rather then hyphens (kebab-case).

MAIN CLASSES
============

Updown
------

The `Updown` object connects the code with all of the monitoring that has been configured for a user of the [Updown.io](https://updown.io) service.

### Parameters

The following parameters can be specified when creating the `Updown` object:

#### client

A `Cro::HTTP::Client` object that will be used to access the API of `Updown`. Defaults to a default `Cro::HTTP::Client` object.

#### api-key

The API key that should be used to authenticate requests with the `Updown` API. Defaults to the `UPDOWN_API_KEY` environment variable.

Any API key (implicitely) specified will be added to the headers of the `client` object used to facilitate authentication.

### Methods

The following methods are available on the `Updown` object:

#### checks

Returns a `Hash` with `Updown::Check` objects, keyed to their "check_id". Takes an optional named boolean argument `:update` to indicate that the information should be refreshed if it was already obtained before.

#### check_ids

Returns a list of "check_id"s of the `Updown::Check`s that are being performed for the user associated with the given API key. Takes an optional named boolean argument `:update` to indicate that the information should be refreshed if it was already obtained before.

#### check

Return the `Updown::Check` object associated with the given "check_id". Takes an optional named boolean argument `:update` to indicate that the information should be refreshed if it was already obtained before.

#### downtimes

Returns a list of up to 100 `Node::Downtime` objects for the given "check_id". Takes an optional `:page` argument to indicate the "page": defaults to `1`.

#### overall_metrics

Returns a `Updown::Metric` object for the given "check_id". Optionally takes two named arguments.

`:from`, a `DateTime` object indicating the **start** of the period for which to provide overall metrics. Defaults to `DateTime.now.earlier(:1month)`.

`:to`, a `DateTime` object indicating the **end** of the period for which to provide overal metrics. Defaults to `DateTime.now`.

#### hourly_metrics

Returns an object `Hash` of `Updown::Metrics` objects for the given "check_id" about overall metrics per hour, keyed to `DateTime` objects indicating the hour. Optionally takes two named arguments.

`:from`, a `DateTime` object indicating the **start** of the period for which to provide overall metrics. Defaults to `DateTime.now.earlier(:1month)`.

`:to`, a `DateTime` object indicating the **end** of the period for which to provide overal metrics. Defaults to `DateTime.now`.

#### node_metrics

Returns a `Hash` of `Updown::Metrics` objects for the given "check_id" about overall metrics per monitoring server in the `Updown.io` network, keyed to "node_id". Optionally takes two named arguments.

`:from`, a `DateTime` object indicating the **start** of the period for which to provide overall metrics. Defaults to `DateTime.now.earlier(:1month)`.

`:to`, a `DateTime` object indicating the **end** of the period for which to provide overal metrics. Defaults to `DateTime.now`.

#### nodes

Returns a `Hash` with `Updown::Node` objects, keyed to their "node_id". Takes an optional named boolean argument `:update` to indicate that the information should be refreshed if it was already obtained before.

#### node_ids

Returns a list of "node_id"s of the monitoring servers of the `Updown.io` network. Takes an optional named boolean argument `:update` to indicate that the information should be refreshed if it was already obtained before.

#### node

Return the `Updown::Node` object associated with the given "node_id". Takes an optional named boolean argument `:update` to indicate that the information should be refreshed if it was already obtained before.

#### ipv4-nodes

Returns a list of strings with the IPv4 numbers of the nodes in the `Updown.io` network that are executing the monitoring checks. Takes an optional named boolean argument `:update` to indicate that the information should be refreshed if it was already obtained before.

#### ipv6-nodes

Returns a list of strings with the IPv6 numbers of the nodes in the `Updown.io` network that are executing the monitoring checks. Takes an optional named boolean argument `:update` to indicate that the information should be refreshed if it was already obtained before.

Updown::Event
-------------

Objects of this type are **not** created automatically, but need to be created **directly** with the hash of the JSON received by a server that handles a webhook (so no `Updown` object needs to have been created).

### event

A string indicating the type of event. Can be either "check.down" when a monitored website appears to be down, or "check.up" to indicate that a monitored website has become operational again.

### check

The associated `Updown::Check` object.

### downtime

The associated `Updown::Node` object.

AUTOMATICALLY CREATED CLASSES
=============================

Updown::Check
-------------

An object containing the configuration of the monitoring that the `Updown.io` network does for a given website.

### disabled_locations

An array of monitoring locations that have been disabled, indicated by `node_id`.

### alias

A string that describes the check, usually a human readable name of the website being monitored.

### apdex_t

A rational number indicating the [APDEX](https://updown.uservoice.com/knowledgebase/articles/915588) threshold.

### custom_headers

A hash of custom headers that will be sent to the monitored website.

### down

A boolean that will be true if the website is currently considered to be down.

### down_since

A `DateTime` object indicating when it was first discovered that the website was down, if down. Else, `Any`.

### enabled

A boolean indicating whether the monitoring is currently active.

### error

A string containing the error that was encountered if the website is considered down.

### favicon_url

The URL of the favicon small icon representing the website, if any.

### http_body

Unclear what the functionality is.

### http_verb

A string describing the HTTP method that will be used to monitor the website. Is one of "GET/HEAD", "POST", "PUT", "PATCH", "DELETE", "OPTIONS".

### last_check_at

A `DateTime` object indicating when the last check was done.

### last_status

An integer indicating the last HTTP status that was received.

### mute_until

A string indicating until when notifications will be muted. Is either a string consisting of "recovery", "forever", or a `DateTime` object indicating until when notifications will be muted, or `Any` if no muting is in effect.

### next_check_at

A `DateTime` object indicating when the next monitoring check will be performed.

### period

An integer indicating the number of seconds between monitoring checks.

### published

A boolean indicating whether the monitoring page is publicly accessible or not.

### ssl

An `Updown::Check::SSL` object, indicating SSL certificate status of the monitored website.

### string_match

A string that should occur in the first 1MB of the body returned by the monitored website. An empty string indicates no content checking is done.

### token

A string indicating the identifier (check-id) of this monitoring check configuration.

### uptime

A rational number between 0 and 100 indicating the percentage uptime of the monitored website.

### url

A string consisting of the URL that will be fetched to assess whether the monitored website is up and running.

Updown::Check::SSL
------------------

This object generally occurs as the `ssl` method in the `Updown::Check` object.

### tested_at

A `DateTime` object indicating when the certificate of the monitored website was checked.

### expires_at

A `DateTime` object indicating when the certificate of the monitored website will expire.

### valid

A boolean indicating whether the certificate of the monitored website was valid the last time it was checked.

### error

A string indicating the error encountered when checking the validity of the certificate of the monitored server, if any.

Updown::Downtime
----------------

An object describing a downtime period as seen by at least one of the monitoring servers in the `Updown.io` network.

### duration

An integer indicating the number of seconds of downtime, or `Any` if the downtime is not ended yet.

### ended_at

A `DateTime` object indicating the moment the downtime appeared to have ended, or `Any` if the downtime is not ended yet..

### error

A string describing the reason the website appeared to be down, e.g. a HTTP status code like "500".

### id

A string identifying this particular downtime.

### partial

A boolean indicating whether the downtime was partial or complete (e.g. not being reachable by IPv6, but operating normally with IPv4).

### started_at

A `DateTime` object indicating the moment the downtime appeared to have started.

Updown::Metrics
---------------

A collection of statistical data applicable for the current situation, or for a certain period, or for a certain `Updown::Node`.

### apdex

A rational number indicating the current [APDEX](https://updown.uservoice.com/knowledgebase/articles/915588) for this set of metrics.

### requests

The associated `Updown::Metrics::Requests` object.

### timings

The associated `Updown::Metrics::Timings` object.

Updown::Metrics::Requests
-------------------------

This object is usually returned by the "requests" method of the `Updown::Metrics` object.

### by_response_time

The associated `Updown::Metrics::Timings::ByResponseTime` object.

### failures

An integer indicating the number of monitoring requests that failed.

### samples

An integer indicating the number of monitoring requests that were done.

### satisfied

An integer indicating the number of monitoring requests that were processed to the user's [APDEX](https://updown.uservoice.com/knowledgebase/articles/915588) satisfaction.

### tolerated

An integer indicating the number of monitoring requests that were processed to the user's [APDEX](https://updown.uservoice.com/knowledgebase/articles/915588) tolerance.

Updown::Metrics::Requests::ByResponseTime
-----------------------------------------

This object is usually returned by the "by_response_time" method of the `Updown::Metrics::Request` object.

head
====

under125

An integer indicating the number of monitoring requests that were processed under 125 milliseconds.

head
====

under250

An integer indicating the number of monitoring requests that were processed under 250 milliseconds.

head
====

under500

An integer indicating the number of monitoring requests that were processed under 500 milliseconds.

head
====

under1000

An integer indicating the number of monitoring requests that were processed under 1 second.

head
====

under2000

An integer indicating the number of monitoring requests that were processed under 2 seconds.

head
====

under4000

An integer indicating the number of monitoring requests that were processed under 4 seconds.

Updown::Metrics::Timings
------------------------

This object is usually returned by the "timings" method of the `Updown::Metrics` object.

### connection

An integer indicating the average number of milliseconds it took to set up a connection with the monitored website.

### handshake

An integer indicating the average number of milliseconds it took to do the TLS handshake with the monitored website.

### namelookup

An integer indicating the average number of milliseconds it took to look up the name of the monitored website.

### redirect

An integer indicating the average number of milliseconds it took to process any redirect that the monitored website did. Any value greater than 0 probably indicates a misconfigured URL of the monitored website.

### response

An integer indicating the average number of milliseconds it took for the monitored website to initiate a response.

### total

An integer indicating the average number of milliseconds it took for the monitored website to complete the monitoring request.

Updown::Node
------------

An object containing information about a monitoring node in the `Updown.io` network.

### city

A string with the name of the city where the monitoring node is located.

### country

A string with the name of the country where the monitoring node is located.

### country_code

A string with the 2-letter code of the country where the monitoring node is located.

### ip

A string indicating the IPv4 number of the monitoring node.

### ip6

A string indicating the IPv6 number of the monitoring node.

### lat

A rational number indicating the latitude of the monitoring node.

### lng

A rational number indicating the longitude of the monitoring node.

### node_id

A string indicating the ID with which the monitoring node can be indicated.

Updown::Webhook
---------------

Objects returned by the `webhooks` method of the `Updown` object.

### id

A string identifying this webhook.

### url

A string with the URL to which any notifications should be sent.

AUTHOR
======

Elizabeth Mattijsen <liz@raku.rocks>

Source can be located at: https://github.com/lizmat/Updown . Comments and Pull Requests are welcome.

COPYRIGHT AND LICENSE
=====================

Copyright 2021 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

