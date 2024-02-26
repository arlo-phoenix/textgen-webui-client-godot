extends TextgenGenerationConfig
class_name TextgenAdvancedGenerationConfig
#https://github.com/oobabooga/text-generation-webui/wiki/03-%E2%80%90-Parameters-Tab


## Primary factor to control the randomness of outputs. 0 = deterministic (only the most likely token is used). Higher value = more randomness.
@export var temperature: float = 0.7

## If not set to 1, select tokens with probabilities adding up to less than this number. Higher value = higher range of possible random results.
@export var top_p: float = 1.0

## Tokens with probability smaller than (min_p) * (probability of the most likely token) are discarded. This is the same as top_a but without squaring the probability.
@export var min_p: float = 0.0

## Similar to top_p, but select instead only the top_k most likely tokens. Higher value = higher range of possible random results.
@export var top_k: int = 40

## Penalty factor for repeating prior tokens. 1 means no penalty, higher value = less repetition, lower value = more repetition.
@export var repetition_penalty: float = 1.0

## Similar to repetition_penalty, but with an additive offset on the raw token scores instead of a multiplicative factor. It may generate better results. 0 means no penalty, higher value = less repetition, lower value = more repetition. Previously called "additive_repetition_penalty".
@export var presence_penalty: float = 0.0

## Repetition penalty that scales based on how many times the token has appeared in the context. Be careful with this; there's no limit to how much a token can be penalized.
@export var frequency_penalty: int = 2.0

## The number of most recent tokens to consider for repetition penalty. 0 makes all tokens be used.
@export var repetition_penalty_range: int = 40

## If not set to 1, select only tokens that are at least this much more likely to appear than random tokens, given the prior text.
@export var typical_p: float = 1.0

## Tries to detect a tail of low-probability tokens in the distribution and removes those tokens. See this blog post for details. The closer to 0, the more discarded tokens.
@export var tfs: float = 3.0

## Tokens with probability smaller than (top_a) * (probability of the most likely token)^2 are discarded.
@export var top_a: float = 0.9

## In units of 1e-4; a reasonable value is 3. This sets a probability floor below which tokens are excluded from being sampled.
@export var epsilon_cutoff: float = 3

## In units of 1e-4; a reasonable value is 3. The main parameter of the special Eta Sampling technique. See this paper for a description.
@export var eta_cutoff: float = 3

## The main parameter for Classifier-Free Guidance (CFG). The paper suggests that 1.5 is a good value. It can be used in conjunction with a negative prompt or not.
@export var guidance_scale: float = 1.5

## Only used when guidance_scale != 1. It is most useful for instruct models and custom system messages. You place your full prompt in this field with the system message replaced with the default one for the model (like "You are Llama, a helpful assistant...") to ake the model pay more attention to your custom system message.
@export var negative_prompt: String = ""

## Contrastive Search is enabled by setting this to greater than zero and unchecking "do_sample". It should be used with a low value of top_k, for instance, top_k = 4.
@export var penalty_alpha: float = 0.0

## Activates the Mirostat sampling technique. It aims to control perplexity during sampling. See the paper.
@export var mirostat_mode: bool = false

## No idea, see the paper for details. According to the Preset Arena, 8 is a good value.
@export var mirostat_tau: float = 8.0

## No idea, see the paper for details. According to the Preset Arena, 0.1 is a good value.
@export var mirostat_eta: float = 0.1

## Makes temperature the last sampler instead of the first. With this, you can remove low probability tokens with a sampler like min_p and then use a high temperature to make the model creative without losing coherency.
@export var temperature_last: bool = false

## When unchecked, sampling is entirely disabled, and greedy decoding is used instead (the most likely token is always picked).
@export var do_sample: bool = true

## Set the Pytorch seed to this number. Note that some loaders do not use Pytorch (notably llama.cpp), and others are not deterministic (notably ExLlama v1 and v2). For these loaders, the seed has no effect.
@export var seed: int = 42

## Used to penalize tokens that are not in the prior text. Higher value = more likely to stay in context, lower value = more likely to diverge.
@export var encoder_repetition_penalty: float = 1.0

## If not set to 0, specifies the length of token sets that are completely blocked from repeating at all. Higher values = blocks larger phrases, lower values = blocks words or letters from repeating. Only 0 or high values are a good idea in most cases.
@export var no_repeat_ngram_size: int = 0

## Minimum generation length in tokens. This is a built-in parameter in the transformers library that has never been very useful. Typically, you want to check "Ban the eos_token" instead.
@export var min_length: int = 0

## Number of beams for beam search. 1 means no beam search.
@export var num_beams: int = 1

## Used by beam search only. length_penalty > 0.0 promotes longer sequences, while length_penalty < 0.0 encourages shorter sequences.
@export var length_penalty: float = 0.0

## Used by beam search only. When checked, the generation stops as soon as there are "num_beams" complete candidates; otherwise, a heuristic is applied and the generation stops when it is very unlikely to find better candidates (I just copied this from the transformers documentation and have never gotten beam search to generate good results).
@export var early_stopping: bool = false

func to_dict() -> Dictionary:
	var dict:=super.to_dict()
	var additional_dict:={
			"temperature": self.temperature,
			"top_p": self.top_p,
			"min_p": self.min_p,
			"top_k": self.top_k,
			"repetition_penalty": self.repetition_penalty,
			"presence_penalty": self.presence_penalty,
			"frequency_penalty": self.frequency_penalty,
			"repetition_penalty_range": self.repetition_penalty_range,
			"typical_p": self.typical_p,
			"tfs": self.tfs,
			"top_a": self.top_a,
			"epsilon_cutoff": self.epsilon_cutoff,
			"eta_cutoff": self.eta_cutoff,
			"guidance_scale": self.guidance_scale,
			"negative_prompt": self.negative_prompt,
			"penalty_alpha": self.penalty_alpha,
			"mirostat_mode": self.mirostat_mode,
			"mirostat_tau": self.mirostat_tau,
			"mirostat_eta": self.mirostat_eta,
			"temperature_last": self.temperature_last,
			"do_sample": self.do_sample,
			"seed": self.seed,
			"encoder_repetition_penalty": self.encoder_repetition_penalty,
			"no_repeat_ngram_size": self.no_repeat_ngram_size,
			"min_length": self.min_length,
			"num_beams": self.num_beams,
			"length_penalty": self.length_penalty,
			"early_stopping": self.early_stopping
		}
	dict.merge(additional_dict)
	return dict
