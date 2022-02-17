use Hash2Class:ver<0.1.5>:auth<zef:lizmat>;
use Cro::HTTP::Client:ver<0.8.7>;

my constant $compare-api-key = 'ro-UME2wrpSpbNGbSuZMRH1';
my constant %compare = <
  booking     mgmi
  duckduckgo  ldxs
  facebook    qhzv
  github      g5ue
  google      ujys
  raku        0211
  reddit      ztqp
  twitter     tpnc
>;

#-------------------------------------------------------------------------------
# Subclasses generated by h2c-skeleton, and tweaked manually after that

class Updown::Check::SSL does Hash2Class[
  error      => Any,
  expires_at => Str,
  tested_at  => Str,
  valid      => Bool,
] { }

class Updown::Check does Hash2Class[
  '@disabled_locations' => Any,
  alias                 => Str,
  apdex_t               => Rat,
  custom_headers        => Hash,
  down                  => Bool,
  enabled               => Bool,
  error                 => Any,
  favicon_url           => Any,
  http_body             => Any,
  http_verb             => Str,
  last_check_at         => DateTime(Str),
  last_status           => Int,
  next_check_at         => DateTime(Str),
  period                => Int,
  published             => Bool,
  ssl                   => Updown::Check::SSL,
  string_match          => Str,
  token                 => Str,
  uptime                => Rat(),
  url                   => Str,
] {
    method mute_until(Updown::Check:D:) {
        with $!data<mute_until> {
            if try .DateTime -> $DateTime {
                $DateTime
            }
            else {
                $_
            }
        }
        else {
            Any
        }
    }
    method down_since(Updown::Check:D:) {
        with $!data<down_since> {
            .DateTime
        }
        else {
            Any
        }
    }

    method title(Updown::Check:D:) { self.alias || self.url }
}

class Updown::Downtime does Hash2Class[
  error      => Any,
  id         => Any,
  partial    => Bool,
  started_at => DateTime(Str),
] {
    method duration(Updown::Downtime:D:) {
        with $!data<duration> {
            .Int
        }
        else {
            Any
        }
    }
    method ended_at(Updown::Downtime:D:) {
        with $!data<ended_at> {
            .DateTime
        }
        else {
            Any
        }
    }
}

class Updown::Metrics::Timings does Hash2Class[
  connection => Int,
  handshake  => Int,
  namelookup => Int,
  redirect   => Int,
  response   => Int,
  total      => Int,
] { }

class Updown::Metrics::Requests::ByResponseTime does Hash2Class[
  under1000 => Int,
  under125  => Int,
  under2000 => Int,
  under250  => Int,
  under4000 => Int,
  under500  => Int,
] { }

class Updown::Metrics::Requests does Hash2Class[
  by_response_time => Updown::Metrics::Requests::ByResponseTime,
  failures         => Int,
  samples          => Int,
  satisfied        => Int,
  tolerated        => Int,
] { }

class Updown::Metrics does Hash2Class[
  apdex    => Rat,
  requests => Updown::Metrics::Requests,
  timings  => Updown::Metrics::Timings,
] { }

class Updown::Node does Hash2Class[
  city         => Str,
  country      => Str,
  country_code => Str,
  ip           => Str,
  ip6          => Str,
  lat          => Rat,
  lng          => Rat,
  node_id      => Str,
] { }

class Updown::Webhook does Hash2Class[
  id  => Str,
  url => Str,
] { }

class Updown::Event does Hash2Class[
  event    => Str,
  check    => Updown::Check,
  downtime => Updown::Downtime,
] { }

#-------------------------------------------------------------------------------
# Updown

class Updown:ver<0.0.5>:auth<zef:lizmat> {
    has Cro::HTTP::Client $.client  is built(:bind);
    has                   $.api-key is built(:bind);
    has Updown::Check     %!checks;
    has Updown::Node      %!nodes;

    submethod TWEAK() {
        $!api-key := %*ENV<UPDOWN_API_KEY>       without $!api-key;
        die "No API key (implicitely) specified" without $!api-key;

        $!client := Cro::HTTP::Client.new(
          base-uri => "https://updown.io/api/",
          headers => (
            User-agent => "Raku UpDown Agent v" ~ Updown.^ver,
          ),
        ) without $!client;
    }

    method !compare-fail(@keys) is hidden-from-backtrace {
        if @keys == 1 {
            die "Unknown compare key: @keys[0]";
        }
        elsif @keys {
            die "Can only specify one compare key: @keys.sort()";
        }
        else {
            die "Missing check_id";
        }
    }

    proto method fetch(|) is implementation-detail {*}
    multi method fetch(Str:D $uri, :$api-key) {
        my $resp := await $!client.get: $uri,
          headers => (X-API-KEY => $api-key // $!api-key,);
        await $resp.body
    }
    multi method fetch(Str:D $uri, $query, :$api-key = $!api-key) {
        my $resp := await $!client.get: $uri,
          headers => (X-API-KEY => $api-key,),
          :$query;
        await $resp.body
    }

    method !checks($api-key) {
        %!checks = self.fetch("checks", :$api-key).map: {
            .<token> => Updown::Check.new($_)
        }
    }

    method !check($check_id, $api-key) {
        %!checks{$check_id} = Updown::Check.new:
          self.fetch: "checks/$check_id", :$api-key
    }

    method !nodes() {
        %!nodes = self.fetch("nodes").map: -> (:key($node_id), :value(%hash)) {
            %hash<node_id> = $node_id;
            $node_id => Updown::Node.new(%hash)
        }
    }

    method checks(Updown:D: :$update) {
        $update || !%!checks ?? self!checks($!api-key) !! %!checks
    }
    method check_ids(Updown:D: :$update) {
        self.checks(:$update).keys
    }

    method nodes(Updown:D: :$update) {
        $update || !%!nodes ?? self!nodes !! %!nodes
    }
    method node_ids(Updown:D: :$update) {
        self.nodes(:$update).keys
    }

    proto method check(|) {*}
    multi method check(Updown:D:) {
        my @keys = %_.keys;
        if @keys == 1 && %compare{@keys[0]} -> $check_id {
            Updown::Check.new:
              self.fetch: "checks/$check_id", :api-key($compare-api-key)
        }
        else {
            self!compare-fail(@keys)
        }
    }
    multi method check(Updown:D:
      Str:D  $check_id,
      Bool  :$update,
      Str:D :$api-key = $!api-key,
    --> Updown::Check) {
        $update || !%!checks
          ?? %!checks  # implies update
            ?? self!check($check_id, $api-key)
            !! self!checks($api-key){$check_id}
          !! %!checks{$check_id}
    }

    method node(Updown:D: $node_id, :$update) {
        ($update || !%!nodes ?? self!nodes !! %!nodes){$node_id}
    }

    method ipv4-nodes(Updown:D: :$update) {
        self.nodes(:$update).values.map: *.ip
    }

    method ipv6-nodes(Updown:D: :$update) {
        self.nodes(:$update).values.map: *.ip6
    }

    proto method downtimes(|) {*}
    multi method downtimes(Updown:D:
      Int:D :$page = 1,
      Str:D :$api-key = $!api-key,
    --> List) {
        my @keys = %_.keys;
        if @keys == 1 && %compare{@keys[0]} -> $check_id {
            self.downtimes: $check_id, :$page, :api-key($compare-api-key)
        }
        else {
            self!compare-fail(@keys)
        }
    }
    multi method downtimes(Updown:D:
      Str:D  $check_id,
      Int:D :$page = 1,
      Str:D :$api-key = $!api-key,
    --> List) {
        self.fetch(
          "checks/$check_id/downtimes",
          %(:$page, :$api-key)
        ).map({
            Updown::Downtime.new($_)
        }).List
    }

    proto method overall_metrics(|) {*}
    multi method overall_metrics(Updown:D:
      DateTime :$from,
      DateTime :$to,
      Str:D    :$api-key = $!api-key,
    --> Updown::Metrics:D) {
        my @keys = %_.keys;
        if @keys == 1 && %compare{@keys[0]} -> $check_id {
            self.overall_metrics:
              $check_id, :$from, :$to, :api-key($compare-api-key)
        }
        else {
            self!compare-fail(@keys)
        }
    }
    multi method overall_metrics(Updown:D:
      Str:D     $check_id,
      DateTime :$from,
      DateTime :$to,
      Str:D    :$api-key = $!api-key,
    --> Updown::Metrics:D) {
        Updown::Metrics.new: self.fetch:
          "checks/$check_id/metrics",
          %((:$from if $from), (:$to if $to), :$api-key)
    }

    proto method hourly_metrics(|) {*}
    multi method hourly_metrics(Updown:D:
      DateTime :$from,
      DateTime :$to,
      Str:D    :$api-key = $!api-key,
    --> Hash) {
        my @keys = %_.keys;
        if @keys == 1 && %compare{@keys[0]} -> $check_id {
            self.hourly_metrics:
              $check_id, :$from, :$to, :api-key($compare-api-key)
        }
        else {
            self!compare-fail(@keys)
        }
    }
    multi method hourly_metrics(Updown:D:
      Str:D     $check_id,
      DateTime :$from,
      DateTime :$to,
      Str:D    :$api-key = $!api-key,
    --> Hash) {
        my Updown::Metrics %metrics{DateTime} = self.fetch(
          "checks/$check_id/metrics",
          %((:$from if $from), (:$to if $to), :group<time>, :$api-key)
        ).map: {
            .key.DateTime => Updown::Metrics.new(.value)
        }
    }

    proto method node_metrics(|) {*}
    multi method node_metrics(Updown:D:
      DateTime :$from,
      DateTime :$to,
      Str:D    :$api-key = $!api-key,
    --> Hash) {
        my @keys = %_.keys;
        if @keys == 1 && %compare{@keys[0]} -> $check_id {
            self.node_metrics:
              $check_id, :$from, :$to, :api-key($compare-api-key)
        }
        else {
            self!compare-fail(@keys)
        }
    }
    multi method node_metrics(Updown:D:
      Str:D     $check_id,
      DateTime :$from,
      DateTime :$to,
      Str:D    :$api-key = $!api-key,
    --> Hash) {
        my Updown::Metrics %metrics{Str} = self.fetch(
          "checks/$check_id/metrics",
          %((:$from if $from), (:$to if $to), :group<host>, :$api-key)
        ).map: {
            .value.DELETE-KEY("host");
            .key => Updown::Metrics.new(.value)
        }
    }

    method webhooks(Updown:D: --> List) {
        self.fetch("webhooks").map({ Updown::Webhook.new($_) }).List
    }
}

# vim: expandtab shiftwidth=4
