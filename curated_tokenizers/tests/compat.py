try:
    import huggingface_hub

    has_huggingface_hub = True
except ImportError:
    huggingface_hub = None  # type: ignore
    has_huggingface_hub = False
