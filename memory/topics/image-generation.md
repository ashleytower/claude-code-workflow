### 2026-02-12 - Nano Banana Pro via Rube MCP
[pattern] Nano Banana Pro (gemini-3-pro-image-preview) is the best image model available through Rube/Composio MCP. GEMINI_GENERATE_IMAGE tool slug. Use RUBE_REMOTE_WORKBENCH with run_composio_tool for parallel generation when RUBE_MULTI_EXECUTE_TOOL is denied by permissions.

[gotcha] RUBE_MULTI_EXECUTE_TOOL was denied in don't-ask mode. Workaround: use RUBE_REMOTE_WORKBENCH with run_composio_tool() helper to execute tools in a Python sandbox instead.

[gotcha] GEMINI_GENERATE_IMAGE response schema: data.data.image.s3url (not data.image_url). URLs are temporary (1-hour expiry via X-Amz-Expires=3600). Must download immediately.

[pattern] Physics-first prompting is the single most impactful technique. Replace adjectives ("ultra-realistic") with camera specs ("Canon 5D Mark IV, 85mm f/1.4, Kodak Portra 400"). Works across all models.

[pattern] UGC degradation for Flux/Nano Banana: "shot on iPhone 15", "compressed", "visible pores", "natural peach fuzz", "candid composition not perfectly centered". Without this, output is too polished.
