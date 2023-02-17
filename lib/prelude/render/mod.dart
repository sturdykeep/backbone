import 'dart:ui';

import 'package:backbone/builders.dart';
import 'package:backbone/entity.dart';
import 'package:backbone/pool.dart';
import 'package:backbone/prelude/render/rectangle.dart';
import 'package:backbone/prelude/render/system.dart';
import 'package:backbone/prelude/render/trait.dart';
import 'package:backbone/prelude/transform.dart';
import 'package:backbone/realm.dart';
import 'package:backbone/trait.dart';

/* ===========================
Short Explanation on Rendering

- PipelineRenderer orchestrates a list of renderers, making sure they switch between each other
  in order to draw things according to their priority.
- Renderer is a segment of the pipeline, which knows how to draw a list of objects with continuous
  priority and stop.  
============================== */

void renderPlugin(RealmBuilder builder) {
  final pipeline = PipelineRenderer()..renderers = [
    RectangleRenderer(),
  ];
  builder.withResource(PipelineRenderer, pipeline);
  builder.withTrait(RenderTrait);
  builder.withTrait(RectangleTrait);
  builder.withRenderSystem(pipelineRenderSystem);
}

/// Resource that includes the state of rendering.
class PipelineRenderer {
  List<Renderer> renderers = [];
  Pool<Renderee> rendereePool = Pool<Renderee>(Renderee.empty, Renderee.reset);
}

/// Segment of the rendering pipeline. Does a priority-based rendering of a batch of objects
/// it is given, then yields control to the next renderer in the pipeline.
abstract class Renderer {
  Trait? matches(Entity entity);
  void render(Iterable<Renderee> renderees, Realm realm, Canvas canvas);
}

class Renderee {
  Entity? entity;
  RenderTrait? renderTrait;
  TransformTrait? transformTrait;
  Trait? matchedTrait;
  Renderer? renderer;

  int get priority => renderTrait!.overridePriority ?? transformTrait?.priority ?? 0; 

  static Renderee empty() {
    return Renderee();
  }
  static void reset(Renderee renderee) {
    renderee.entity = null;
    renderee.renderTrait = null;
    renderee.transformTrait = null;
    renderee.matchedTrait = null;
    renderee.renderer = null;
  }
}