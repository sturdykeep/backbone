import 'dart:ui';

import 'package:backbone/filter.dart';
import 'package:backbone/prelude/render/mod.dart';
import 'package:backbone/prelude/render/trait.dart';
import 'package:backbone/prelude/transform.dart';
import 'package:backbone/realm.dart';

void pipelineRenderSystem(Realm realm, Canvas canvas) {
  // TODO: I am sure this can be optimized, a lot.
  final pipeline = realm.getResource<PipelineRenderer>();
  final query = realm.query(Has([RenderTrait]));

  final List<Renderee> renderees = [];
  for (final entity in query) {
    final renderTrait = entity.get<RenderTrait>();
    final transformTrait = entity.tryGet<TransformTrait>();

    final renderee = pipeline.rendereePool.get();
    renderee.entity = entity;
    renderee.renderTrait = renderTrait;
    renderee.transformTrait = transformTrait;
    renderee.matchedTrait = null;
    renderees.add(renderee);
  }

  // Sort renderees by priority
  renderees.sort((a, b) => a.priority.compareTo(b.priority));

  // Fill the matched renderer and trait for each renderee
  for (final renderee in renderees) {
    for (final renderer in pipeline.renderers) {
      final trait = renderer.matches(renderee.entity!);
      if (trait != null) {
        renderee.matchedTrait = trait;
        renderee.renderer = renderer;
        break;
      }
    }
  }

  // Now do rendering in batches until all renderees are rendered
  while (renderees.isNotEmpty) {
    final renderer = renderees.first.renderer!;
    final batch = renderees.takeWhile((renderee) => renderee.renderer == renderer);
    renderer.render(batch, realm, canvas);
    
    // Remove and free the renderees that were rendered
    for (var r in batch) {
      renderees.remove(r);
      pipeline.rendereePool.release(r);
    }
  }
}