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

- [[humpback-whale-song]] — ocean-basin-scale consensus song; evolves continuously; same combination never recurs in 19 years
- [[orca-pod-dialects]] — pod-specific pulsed call dialects; stable, matrilineally transmitted; "no parallel outside humans" (Ford & Ellis)
- [[chimpanzee-gesture-repertoire]] — ~66 gesture types; consistent across populations; ~30 shared with bonobos; intentional

### Deceptive Signalling

- [[fork-tailed-drongo-false-alarms]] — mimics alarm calls of meerkats, babblers, raptors; varies to prevent habituation; ~25% of diet
- [[mimic-octopus-dynamic-mimicry]] — up to 18 species mimicked simultaneously; context-appropriate (damselfish → sea snake)
- [[killdeer-broken-wing-display]] — injury feigning; lures terrestrial predators from nest; intensity scales with reproductive investment
- [[common-cuckoo-brood-parasitism]] — egg mimicry, adult sparrowhawk mimicry, chick brood-sound mimicry — three simultaneous deceptions
- [[photuris-firefly-aggressive-mimicry]] — female mimics Photinus mate-attraction flashes to lure and eat males

### Cross-Species Communication

- [[diana-monkey-alarm-calls]] — hornbill/Diana monkey mutualistic warning network
- [[fork-tailed-drongo-false-alarms]] — exploits cross-species alarm comprehension for deception

### Multimodal and Cognitively Striking

- [[honeybee-waggle-dance]] — direction + distance encoded in figure-eight; 4 simultaneous signal channels; most information-dense non-human signal
- [[bird-of-paradise-lek-displays]] — correlated complexity across plumage, dance, and sound; female preference drives 24 million years of elaboration
- [[bowerbird-extended-phenotype-display]] — bower as signal artifact; forced-perspective optical illusion; plumage transferred to constructed object

## Signal Modality Index

- **Acoustic — vocal:** [[vervet-monkey-alarm-calls]], [[diana-monkey-alarm-calls]], [[black-capped-chickadee-dee-count]], [[prairie-dog-slobodchikoff-calls]], [[fork-tailed-drongo-false-alarms]], [[humpback-whale-song]], [[orca-pod-dialects]], [[chimpanzee-gesture-repertoire]]
- **Acoustic — non-vocal:**
- **Visual:** [[mimic-octopus-dynamic-mimicry]], [[killdeer-broken-wing-display]], [[common-cuckoo-brood-parasitism]], [[bowerbird-extended-phenotype-display]], [[chimpanzee-gesture-repertoire]], [[mantis-shrimp-polarized-light-signals]], [[cuttlefish-chromatophore-signaling]], [[photuris-firefly-aggressive-mimicry]]
- **Multimodal:** [[honeybee-waggle-dance]], [[bird-of-paradise-lek-displays]]
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
- 2026-05-06: Batch 1 indexed (10 Wikipedia pages, 108 chunks); synthesized [[jakob-von-uexkull-umwelt]], [[diana-monkey-alarm-calls]], [[black-capped-chickadee-dee-count]], [[prairie-dog-slobodchikoff-calls]]
- 2026-05-06: Batch 2 indexed (15 Wikipedia pages, 227 chunks); synthesized [[humpback-whale-song]], [[fork-tailed-drongo-false-alarms]], [[mimic-octopus-dynamic-mimicry]], [[honeybee-waggle-dance]]
- 2026-05-06: Full synthesis pass — 9 additional notes: [[orca-pod-dialects]], [[chimpanzee-gesture-repertoire]], [[killdeer-broken-wing-display]], [[common-cuckoo-brood-parasitism]], [[cuttlefish-chromatophore-signaling]], [[mantis-shrimp-polarized-light-signals]], [[bowerbird-extended-phenotype-display]], [[bird-of-paradise-lek-displays]], [[photuris-firefly-aggressive-mimicry]]
