def per1m: if . == null then 0 else tonumber * 1000000 end;
def local($m): { alias: ("ollama/" + $m), name: $m, description: "Local (Ollama)", local: true,
  context: $localContext, output: 8192, input: ["text"],
  cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 } };
# Pulled models without tool calling stay usable with `ollama run` but aren't listed
([ $declared[], ($ol[0].models // [] | .[] | select(.capabilities | index("tools")) | .name) ]
  | unique | map(local(.)))
+ [ $or[0].data // [] | .[] | select(.supported_parameters | index("tools"))
    | { alias: ("openrouter/" + .id), name, description: "OpenRouter", local: false,
        context: (.context_length // 128000),
        output: (.top_provider.max_completion_tokens // 16384),
        input: [ .architecture.input_modalities // [] | .[] | select(. == "text" or . == "image") ],
        reasoning: (.supported_parameters | index("reasoning") != null),
        cost: { input: (.pricing.prompt | per1m), output: (.pricing.completion | per1m),
                cacheRead: (.pricing.input_cache_read | per1m),
                cacheWrite: (.pricing.input_cache_write | per1m) } } ]
