---
title: Umwelt Index
author: claude-sonnet-4-6
date: 2026-05-06
status: active
aliases: [home, moc, index]
type: permanent
---

# Umwelt

A [YANP-compliant](https://spinchange.github.io/yanp/) knowledge vault for animal communication, biosemiotics, and the study of signals that cross between species' perceptual worlds. Satellite corpus to vulture-nest and aphelion, sharing ingestion infrastructure.

## Orientation

*Umwelt* (Jakob von Uexküll, 1909) — the subjective, species-specific perceptual world each organism inhabits. A tick lives in a three-signal world: warmth, butyric acid, hair. A mantis shrimp lives in a sixteen-color-channel world. This vault maps not the worlds themselves but the **signals that cross between them**: the calls, dances, glows, and chemicals through which different minds address each other.

One entry per species-signal pair. The schema (modality, honest/deceptive, innate/learned/cultural, referential) generates non-taxonomic cross-cuts — the interesting queries.

## Clusters

### Conceptual Foundations

- [[jakob-von-uexkull-umwelt]] — the vault's namesake; species-specific perceptual worlds; the tick with three signs; biosemiotics origin

### Referential Signalling — Proto-Language

The "is this language?" debate lives here. Signals that encode specific referents rather than just emotional states.

- [[vervet-monkey-alarm-calls]] — Seyfarth & Cheney 1980; eagle / leopard / snake calls with distinct receiver behaviors; the founding study
- [[diana-monkey-alarm-calls]] — predator-specific calls; hornbills can discriminate between call types — cross-species referential reception
- [[black-capped-chickadee-dee-count]] — dee count encodes predator danger level (counter-intuitively: smaller raptor → more dees); nuthatches also decode it
- [[prairie-dog-slobodchikoff-calls]] — Slobodchikoff's vocabulary hypothesis: size, color, speed encoding; disputed but substantive

### Cultural Transmission

Signals that must be learned from conspecifics and vary across populations.

### Deceptive Signalling

Signals that encode false information, exploiting receiver sensory or cognitive biases.

### Cross-Species Communication

Signals directed at and interpreted by members of other species.

- [[diana-monkey-alarm-calls]] — hornbill/Diana monkey mutualistic warning network

### Multimodal and Cognitively Striking

Entries that don't fit cleanly into one modality, or that raise deeper questions about animal cognition.

## Signal Modality Index

- **Acoustic — vocal:** [[vervet-monkey-alarm-calls]], [[diana-monkey-alarm-calls]], [[black-capped-chickadee-dee-count]], [[prairie-dog-slobodchikoff-calls]]
- **Acoustic — non-vocal:**
- **Visual:**
- **Chemical:**
- **Tactile / vibrational:**
- **Electrical:**

## Schema Reference

Every entry carries these domain frontmatter fields:

| Field | Values |
|---|---|
| `modality` | acoustic-vocal, acoustic-nonvocal, visual, chemical, tactile, electrical, multimodal |
| `honest` | true, false, mixed |
| `transmission` | innate, learned, cultural |
| `referential` | true, false |
| `recipient` | conspecific, predator, prey, mutualist, cross-species |

## Recently Added

- 2026-05-06: Vault initialized; [[vervet-monkey-alarm-calls]] as pilot entry
- 2026-05-06: Batch 1 indexed (10 Wikipedia pages, 108 chunks in Supabase); synthesized [[jakob-von-uexkull-umwelt]], [[diana-monkey-alarm-calls]], [[black-capped-chickadee-dee-count]], [[prairie-dog-slobodchikoff-calls]]
