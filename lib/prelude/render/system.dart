import 'dart:ui';

import 'package:backbone/filter.dart';
import 'package:backbone/prelude/render/mod.dart';
import 'package:backbone/prelude/render/trait.dart';
import 'package:backbone/prelude/transform.dart';
import 'package:backbone/realm.dart';
import 'package:flutter/foundation.dart';

void pipelineRenderSystem(Realm realm, Canvas canvas) {
  // Check if in debug mode in Flutter
  final debug = realm.debugMode;
  if (debug) {
    debugPrint('[Rendering pipeline] New frame');
  }

  // TODO: I am sure this can be optimized, a lot.
  final pipeline = realm.resource<PipelineRenderer>();
  final query = realm.query(Has([Renderable]));

  final List<Renderee> renderees = [];
  for (final entity in query) {
    final renderTrait = entity.get<Renderable>();
    final transformTrait = entity.tryGet<Transform>();

    final renderee = pipeline.rendereePool.get();
    renderee.entity = entity;
    renderee.renderTrait = renderTrait;
    renderee.transformTrait = transformTrait;
    renderee.matchedVisual = null;
    renderees.add(renderee);
  }

  // Sort renderees by priority
  renderees.sort((a, b) => a.priority.compareTo(b.priority));

  // Go through renderees one by one, building up a batch and rendering it
  // when the batch matching fails
  int toRender = 0;
  List<Renderee> batch = [];
  Renderer? currentRenderer;
  while (toRender < renderees.length) {
    final renderee = renderees[toRender];
    final renderTrait = renderee.renderTrait!;
    final transformTrait = renderee.transformTrait;

    // If the renderee is not visible, or it doesn't have a transform, skip it
    if (renderTrait.visual == null || transformTrait == null) {
      toRender++;
      continue;
    }

    if (currentRenderer == null) {
      // If we don't have a renderer yet, try to find one
      for (final renderer in pipeline.renderers) {
        final visual = renderer.matches(renderee.entity!);
        if (visual != null) {
          renderee.matchedVisual = visual;
          renderee.renderer = renderer;
          currentRenderer = renderer;
          batch = [renderee];
          toRender++;
          break;
        }
      }
    } else {
      // If we have a renderer, try to match the renderee with it
      final visual = currentRenderer.matches(renderee.entity!);
      if (visual != null) {
        renderee.matchedVisual = visual;
        renderee.renderer = currentRenderer;
        batch.add(renderee);
        toRender++;
      } else {
        // If the renderee doesn't match the renderer, render the batch
        // and start a new one
        currentRenderer.render(batch, realm, canvas);
        if (debug) {
          debugPrint(
              '[Rendering pipeline] Rendered ${batch.length} objects with priority ${batch.first.priority} to ${batch.last.priority} using ${currentRenderer.runtimeType}');
        }
        currentRenderer = null;
        batch = [];
      }
    }
  }

  if (batch.isNotEmpty) {
    // Do a final render of the last batch
    currentRenderer!.render(batch, realm, canvas);
    if (debug) {
      debugPrint(
          '[Rendering pipeline] Rendered ${batch.length} objects with priority ${batch.first.priority} to ${batch.last.priority} using ${currentRenderer.runtimeType}');
    }
  }

  // Free renderees
  for (final renderee in renderees) {
    pipeline.rendereePool.release(renderee);
  }

  if (debug) {
    debugPrint('[Rendering pipeline] Finished rendering');
  }
}
