from unittest.mock import patch


def test_azure_foundry_picker_shows_live_models(tmp_path, monkeypatch):
    from hermes_cli.model_switch import list_authenticated_providers

    monkeypatch.setenv("HERMES_HOME", str(tmp_path))
    monkeypatch.setenv("AZURE_FOUNDRY_API_KEY", "az-key")
    monkeypatch.setenv("AZURE_FOUNDRY_BASE_URL", "https://my-resource.openai.azure.com/openai/v1")
    monkeypatch.setenv("AZURE_FOUNDRY_MODEL_SOURCE", "models")

    with patch("agent.models_dev.fetch_models_dev", return_value={}):
        with patch(
            "hermes_cli.auth.resolve_api_key_provider_credentials",
            return_value={
                "api_key": "az-key",
                "base_url": "https://my-resource.openai.azure.com/openai/v1",
            },
        ), patch(
            "hermes_cli.azure_detect._probe_openai_models",
            return_value=(True, ["gpt-4o-mini", "gpt-4.1-mini"]),
        ):
            providers = list_authenticated_providers(current_provider="azure-foundry", max_models=50)

    azure = next((p for p in providers if p["slug"] == "azure-foundry"), None)
    assert azure is not None
    assert azure["total_models"] == 2
    assert azure["models"] == ["gpt-4.1-mini", "gpt-4o-mini"]


def test_azure_foundry_picker_not_truncated_by_max_models(tmp_path, monkeypatch):
    from hermes_cli.model_switch import list_authenticated_providers

    monkeypatch.setenv("HERMES_HOME", str(tmp_path))
    monkeypatch.setenv("AZURE_FOUNDRY_API_KEY", "az-key")
    monkeypatch.setenv("AZURE_FOUNDRY_BASE_URL", "https://my-resource.openai.azure.com/openai/v1")
    monkeypatch.setenv("AZURE_FOUNDRY_MODEL_SOURCE", "models")

    models = [
        "gpt-4o-mini-2024-07-18",
        "gpt-4o-mini",
        "gpt-4.1-mini-2025-04-14",
        "gpt-4.1-mini",
    ]

    with patch("agent.models_dev.fetch_models_dev", return_value={}):
        with patch(
            "hermes_cli.auth.resolve_api_key_provider_credentials",
            return_value={
                "api_key": "az-key",
                "base_url": "https://my-resource.openai.azure.com/openai/v1",
            },
        ), patch(
            "hermes_cli.azure_detect._probe_openai_models",
            return_value=(True, models),
        ):
            providers = list_authenticated_providers(current_provider="azure-foundry", max_models=1)

    azure = next((p for p in providers if p["slug"] == "azure-foundry"), None)
    assert azure is not None
    assert azure["total_models"] == 4
    assert azure["models"] == [
        "gpt-4.1-mini",
        "gpt-4o-mini",
        "gpt-4.1-mini-2025-04-14",
        "gpt-4o-mini-2024-07-18",
    ]
