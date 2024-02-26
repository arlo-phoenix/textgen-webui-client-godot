# Textgen WebUI Client

This is an openAI compatible client library for [text-generation-webui](https://github.com/oobabooga/text-generation-webui).

For an example see [api_test](addons/textgen_nodes/example/api_test.gd) which showcases the low level, high level and node API. I generally recommend just using the **TextgenChatNode** as this is the simplest to use and uses a shared connection through a **TextgenServer** singleton. This is also written asynchronously so it should be a lot easier to use.

If you don't use the default config you'll need to configure the port and server address in `core/textgen_api_connector.gd`. Everything is based on this openAI client (the low level API).

This project is licensed under the AGPLv3 since I just copied over the API configs from the webui which is licensed under AGPLv3. I plan to update the files under `config/` and remove the internal API in `core/textgen_api_connector.gd` in the future so this can be licensed under MIT under another repo. This project itself is adapted from an very old OpenAI client I wrote based on the openAI python library so there'll be no licensing issues there. I'll either target vLLM or llama.cpp, it should even work now, but never tested with another API.