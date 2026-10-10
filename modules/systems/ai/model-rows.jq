def per1m: if . == null then null else tonumber * 1000000 end;
def usd: if . == null then "-" elif . == 0 then "free" elif . < 0.01 then "<$0.01"
  else (. * 100 | round | tostring | (if length < 3 then ("00" + .)[-3:] else . end))
    | "$" + .[:-2] + "." + .[-2:] end;
def ctx: if . == null then "" elif . >= 1000000 then "\(. / 100000 | round / 10)M ctx"
  elif . >= 1000 then "\(. / 1000 | round)K ctx" else "\(.) ctx" end;
def gb: "\(. / 1e8 | round / 10) GB";
def pad($n): tostring | .[0:$n] | . + " " * ($n - length);

($or[0].data // [] | map({ key: ("openrouter/" + .id), value: . }) | from_entries) as $routes
| ($ol[0].models // [] | map({ key: ("ollama/" + .name), value: . }) | from_entries) as $locals
| $srv[0].models
| (map(select(.alias == $cur)) + map(select(.alias != $cur)))[]
| .alias as $a
| ($routes[$a]) as $r
| ($locals[$a]) as $l
| (if $a == $cur then "* " else "  " end) + (.name | pad(40)) + "  " as $lead
| if ($a | startswith("ollama/")) then
    [ $a,
      $lead + ("local" | pad(18)) + "  "
        + ("\($l.details.parameter_size // "?") \($l.details.quantization_level // "")" | pad(14))
        + ($l.size | if . then gb else "" end),
      ([ .name, $a, "",
         "Runs locally with Ollama (free)",
         "Parameters:   \($l.details.parameter_size // "?")",
         "Quantization: \($l.details.quantization_level // "?")",
         "Family:       \($l.details.family // "?")",
         "Size on disk: \($l.size | if . then gb else "?" end)"
       ] | join("\\n"))
    ]
  else
    ($r.pricing.prompt | per1m) as $in
    | ($r.pricing.completion | per1m) as $out
    | [ $a,
        $lead + ("\($in | usd) / \($out | usd)" | pad(18)) + "  " + ($r.context_length | ctx),
        ([ .name, $a, "",
           "Price per 1M tokens",
           "  input:       \($in | usd)",
           "  output:      \($out | usd)",
           "  cache read:  \($r.pricing.input_cache_read | per1m | usd)",
           "  cache write: \($r.pricing.input_cache_write | per1m | usd)",
           "  web search:  \($r.pricing.web_search | if . == null then "-" else "$\(.) / search" end)",
           "",
           "Context:     \($r.context_length | ctx)",
           "Max output:  \($r.top_provider.max_completion_tokens // "?") tokens",
           "Inputs:      \($r.architecture.input_modalities // [] | join(", "))",
           "",
           ($r.description // "" | gsub("[\\t\\n]+"; " "))
         ] | join("\\n"))
      ]
  end
| @tsv
