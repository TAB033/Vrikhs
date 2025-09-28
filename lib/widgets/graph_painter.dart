import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import '../models/node.dart';

class AnimatedGraphPainter extends CustomPainter {
  final Map<int, List<GraphNode>> nodesByDepth;
  final GraphNode? selectedNode;
  final Function(GraphNode) onNodeTap;
  final Size canvasSize;
  final double selectionAnimation;
  final double pulseAnimation;
  final double connectionAnimation;

  AnimatedGraphPainter({
    required this.nodesByDepth,
    required this.selectedNode,
    required this.onNodeTap,
    required this.canvasSize,
    required this.selectionAnimation,
    required this.pulseAnimation,
    required this.connectionAnimation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw gradient background
    _drawBackground(canvas, size);

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Calculate positions for all nodes
    Map<GraphNode, Offset> nodePositions = _calculateNodePositions(size);

    // Draw animated connections first (so they appear behind nodes)
    _drawAnimatedConnections(canvas, nodePositions);

    // Draw nodes with enhanced effects
    _drawEnhancedNodes(canvas, textPainter, nodePositions);

    // Draw particle effects for selected node
    if (selectedNode != null) {
      _drawParticleEffects(canvas, nodePositions[selectedNode!]);
    }
  }

  // Calculate the size of the subtree rooted at each node
  Map<GraphNode, double> _calculateSubtreeWidths() {
    final Map<GraphNode, double> subtreeWidths = {};
    
    // Process nodes from bottom to top
    final depths = nodesByDepth.keys.toList()..sort((a, b) => b.compareTo(a));
    
    for (final depth in depths) {
      for (final node in nodesByDepth[depth]!) {
        if (node.children.isEmpty) {
          // Leaf nodes have a fixed width
          subtreeWidths[node] = 100.0; // Base width for leaf nodes
        } else {
          // Calculate total width needed for children
          double totalWidth = 0.0;
          for (final child in node.children) {
            totalWidth += subtreeWidths[child] ?? 0.0;
          }
          // Add spacing between children
          if (node.children.length > 1) {
            totalWidth += (node.children.length - 1) * 40.0; // Spacing between children
          }
          subtreeWidths[node] = totalWidth;
        }
      }
    }
    
    return subtreeWidths;
  }

  // Assign x-positions to nodes using a depth-first traversal
  void _assignPositions(
    GraphNode node,
    double x,
    double y,
    Map<GraphNode, Offset> positions,
    Map<GraphNode, double> subtreeWidths,
    double verticalSpacing
  ) {
    // If we've already positioned this node, return
    if (positions.containsKey(node)) return;
    
    // Position the current node
    positions[node] = Offset(x, y);
    
    // If it's a leaf node, we're done
    if (node.children.isEmpty) return;
    
    // Calculate total width of all children
    double totalWidth = 0.0;
    for (final child in node.children) {
      totalWidth += subtreeWidths[child] ?? 0.0;
    }
    
    // Add spacing between children
    if (node.children.length > 1) {
      totalWidth += (node.children.length - 1) * 40.0; // Spacing between children
    }
    
    // Calculate starting x position to center children under parent
    double currentX = x - (totalWidth / 2);
    
    // Position each child
    for (final child in node.children) {
      final childWidth = subtreeWidths[child] ?? 0.0;
      _assignPositions(
        child,
        currentX + (childWidth / 2), // Center the child in its allocated space
        y + verticalSpacing,
        positions,
        subtreeWidths,
        verticalSpacing
      );
      currentX += childWidth + 40.0; // Move to next child position
    }
  }

  Map<GraphNode, Offset> _calculateNodePositions(Size size) {
    final Map<GraphNode, Offset> positions = {};
    
    if (nodesByDepth.isEmpty) return positions;
    
    // Calculate responsive spacing
    final isMobile = size.width < 600;
    final verticalSpacing = isMobile ? 120.0 : 160.0;
    
    // Calculate subtree widths for all nodes
    final subtreeWidths = _calculateSubtreeWidths();
    
    // Find root nodes (nodes with no parents)
    final Set<GraphNode> allNodes = {};
    final Set<GraphNode> children = {};
    
    nodesByDepth.values.forEach((nodes) {
      allNodes.addAll(nodes);
      nodes.forEach((node) {
        children.addAll(node.children);
      });
    });
    
    final List<GraphNode> rootNodes = allNodes.where((node) => !children.contains(node)).toList();
    
    // Position root nodes
    double currentX = 0.0;
    for (final root in rootNodes) {
      final rootWidth = subtreeWidths[root] ?? 0.0;
      _assignPositions(
        root,
        currentX + (rootWidth / 2), // Center the root in its allocated space
        100.0, // Top padding
        positions,
        subtreeWidths,
        verticalSpacing
      );
      currentX += rootWidth + 200.0; // Add extra spacing between root trees
    }
    
    return positions;
  }

  void _drawBackground(Canvas canvas, Size size) {
    // Solid background color for the entire infinite plane
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..color = const Color(0xFFfefae0)  // Light beige color
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(rect, paint);
  }
  
  // Removed grid pattern - using solid color background only

  void _drawAnimatedConnections(Canvas canvas, Map<GraphNode, Offset> positions) {
    positions.forEach((node, position) {
      for (GraphNode child in node.children) {
        final childPosition = positions[child];
        if (childPosition != null) {
          _drawAnimatedConnection(canvas, position, childPosition);
        }
      }
    });
  }

  void _drawAnimatedConnection(Canvas canvas, Offset start, Offset end) {
    // Responsive line thickness
    final isMobile = canvasSize.width < 600;
    final baseStrokeWidth = isMobile ? 3.0 : 4.0;
    
    // Calculate points for the branch-like path
    final verticalLineEnd = Offset(start.dx, start.dy + 80);
    
    // Create a more organic, curved path
    final path = Path();
    path.moveTo(start.dx, start.dy);
    
    // Vertical line with subtle curve
    final controlY1 = start.dy + (verticalLineEnd.dy - start.dy) * 0.4;
    final controlY2 = start.dy + (verticalLineEnd.dy - start.dy) * 0.6;
    
    path.cubicTo(
      start.dx, controlY1,  // control point 1
      start.dx, controlY2,  // control point 2
      verticalLineEnd.dx, verticalLineEnd.dy  // end point
    );
    
    // Horizontal line with subtle curve
    final midY = verticalLineEnd.dy;
    final midX = (verticalLineEnd.dx + end.dx) / 2;
    
    path.lineTo(midX, midY);
    
    // Final vertical line to child with subtle curve
    final controlY3 = midY + (end.dy - midY) * 0.3;
    final controlY4 = midY + (end.dy - midY) * 0.7;
    
    path.cubicTo(
      end.dx, controlY3,  // control point 1
      end.dx, controlY4,  // control point 2
      end.dx, end.dy - 5  // end just before the node
    );
    
    // Draw the branch with wood-like appearance
    final paint = Paint()
      ..color = const Color(0xFF5D4037)  // Dark brown base
      ..strokeWidth = baseStrokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF5D4037),  // Dark brown
          const Color(0xFF8D6E63),  // Lighter brown
          const Color(0xFF5D4037),  // Dark brown
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromPoints(start, end));
    
    // Draw the main branch
    canvas.drawPath(path, paint);
    
    // Add some texture with small lines
    final texturePaint = Paint()
      ..color = const Color(0x40FFFFFF)  // Semi-transparent white for highlights
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    
    // Draw some subtle lines to simulate wood grain
    final grainPath = Path();
    final grainCount = 5;
    final grainSpacing = baseStrokeWidth / grainCount;
    
    for (var i = 0; i < grainCount; i++) {
      final offset = (i - grainCount / 2) * grainSpacing;
      grainPath.reset();
      grainPath.moveTo(start.dx + offset, start.dy);
      grainPath.cubicTo(
        start.dx + offset, controlY1,
        start.dx + offset, controlY2,
        verticalLineEnd.dx + offset, verticalLineEnd.dy
      );
      grainPath.lineTo(midX + offset, midY);
      grainPath.cubicTo(
        end.dx + offset, controlY3,
        end.dx + offset, controlY4,
        end.dx + offset, end.dy - 5
      );
      
      canvas.drawPath(grainPath, texturePaint);
    }
  }
  
  // Removed particle animation - now using simple static connections

  void _drawEnhancedNodes(Canvas canvas, TextPainter textPainter, Map<GraphNode, Offset> positions) {
    positions.forEach((node, position) {
      _drawSingleNode(canvas, textPainter, node, position);
    });
  }

  void _drawSingleNode(Canvas canvas, TextPainter textPainter, GraphNode node, Offset position) {
    // Responsive node sizing
    final isMobile = canvasSize.width < 600;
    final baseSize = isMobile ? 28.8 : 43.2; // Increased by 20% from 24/36 to 28.8/43.2
    final isSelected = node == selectedNode;
    final pulseEffect = isSelected ? (1.0 + 0.2 * math.sin(pulseAnimation * 2 * math.pi)) : 1.0;
    var nodeSize = baseSize * pulseEffect;
    if (isSelected) {
      nodeSize += (isMobile ? 4.0 : 8.0) * selectionAnimation;
    }
    
    // Save canvas state for rotation
    canvas.save();
    
    // Rotate canvas 45 degrees (π/4 radians) around the node position
    canvas.translate(position.dx, position.dy);
    canvas.rotate(math.pi / 4); // 45 degrees clockwise
    canvas.translate(-position.dx, -position.dy);
    
    // Create leaf shape path
    final leafPath = _createLeafPath(position, nodeSize);
    
    // Draw outer glow only for selected node
    if (isSelected) {
      final glowPaint = Paint()
        ..color = _getNodeColor(node).withValues(alpha: 0.4)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15.0);
      
      canvas.drawPath(leafPath, glowPaint);
    }
    
    // Draw shadow (static for all nodes) - using baseSize for consistent shadow
    final shadowPath = _createLeafPath(position + const Offset(3, 3), baseSize);
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
    
    canvas.drawPath(shadowPath, shadowPaint);
    
    // Draw gradient leaf with pulse effect for selected node
    final gradient = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        _getNodeColor(node).withValues(alpha: 0.9),
        _getNodeColor(node),
        _getNodeColor(node).withValues(alpha: 0.7),
      ],
      stops: const [0.0, 0.5, 1.0],
    );
    
    final leafBounds = leafPath.getBounds();
    final nodePaint = Paint()
      ..shader = gradient.createShader(leafBounds)
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(leafPath, nodePaint);
    
    // Draw leaf stem separately to ensure it's visible for all nodes
    final stemPaint = Paint()
      ..color = const Color(0xFF008000) // Forest green for stems
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final stemLength = nodeSize * 0.3;
    canvas.drawLine(
      Offset(position.dx, position.dy + nodeSize * 0.7),
      Offset(position.dx, position.dy + nodeSize * 0.7 + stemLength),
      stemPaint,
    );
    
    // Draw leaf vein (center line) - adjusted for stem
    final veinPaint = Paint()
      ..color = const Color(0xFF9ef01a) // Bright lime green for veins
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    canvas.drawLine(
      Offset(position.dx, position.dy - nodeSize * 0.8),
      Offset(position.dx, position.dy + nodeSize * 0.7),
      veinPaint,
    );
    
    // Draw selection ring with animation
    if (isSelected) {
      final ringPaint = Paint()
        ..color = const Color(0xFF38b000) // Beautiful green for selection
        ..strokeWidth = 4.0 + (2.0 * selectionAnimation)
        ..style = PaintingStyle.stroke;
      
      canvas.drawPath(leafPath, ringPaint);
    }
    
    // Restore canvas state before drawing text (so text isn't rotated)
    canvas.restore();
    
    // Removed revolving dots around selected node as per user request
    
    // Draw node ID with responsive sizing (text remains upright)
    // Increased font sizes and made text darker for better visibility
    final fontSize = isMobile 
        ? (isSelected ? 20.0 : 18.0)  // Increased from 14/12
        : (isSelected ? 28.0 : 24.0); // Increased from 20/18
    
    textPainter.text = TextSpan(
      text: node.id,
      style: GoogleFonts.poppins(
        color: Colors.black, // Pure black for maximum contrast
        fontSize: fontSize,
        fontWeight: FontWeight.w900, // Extra bold
        shadows: [
          // White border/stroke effect (8 directions)
          Shadow( // Top
            color: Colors.white,
            blurRadius: 0,
            offset: const Offset(0, -2),
          ),
          Shadow( // Bottom
            color: Colors.white,
            blurRadius: 0,
            offset: const Offset(0, 2),
          ),
          Shadow( // Left
            color: Colors.white,
            blurRadius: 0,
            offset: const Offset(-2, 0),
          ),
          Shadow( // Right
            color: Colors.white,
            blurRadius: 0,
            offset: const Offset(2, 0),
          ),
          // Diagonal directions for better coverage
          Shadow( // Top-Left
            color: Colors.white,
            blurRadius: 0,
            offset: const Offset(-1.5, -1.5),
          ),
          Shadow( // Top-Right
            color: Colors.white,
            blurRadius: 0,
            offset: const Offset(1.5, -1.5),
          ),
          Shadow( // Bottom-Left
            color: Colors.white,
            blurRadius: 0,
            offset: const Offset(-1.5, 1.5),
          ),
          Shadow( // Bottom-Right
            color: Colors.white,
            blurRadius: 0,
            offset: const Offset(1.5, 1.5),
          ),
          // Glow effect
          Shadow(
            color: Colors.white.withOpacity(0.7),
            blurRadius: 10,
            offset: Offset.zero,
          ),
        ],
        letterSpacing: 0.5, // Slightly increased letter spacing for better readability
      ),
    );
    textPainter.layout();
    
    final textOffset = Offset(
      position.dx - textPainter.width / 2,
      position.dy - textPainter.height / 2,
    );
    textPainter.paint(canvas, textOffset);
  }

  Path _createLeafPath(Offset center, double size) {
    final path = Path();
    
    // Use exact LeafClipper proportions: width 70, height 90 (ratio 7:9)
    final width = size * (70.0 / 60.0) * 2.0;  // Scale to match 70:90 ratio
    final height = size * 2.0; // Base height scaling
    final stemLength = size * 0.3; // Add stem length
    
    // Calculate the bounds for the leaf
    final left = center.dx - width / 2;
    final right = center.dx + width / 2;
    final top = center.dy - height / 2;
    final bottom = center.dy + height / 2 - stemLength; // Adjust for stem
    final stemBottom = center.dy + height / 2; // Bottom of stem
    
    // Start from the bottom of the stem
    path.moveTo(center.dx, stemBottom);
    
    // Draw the stem (vertical line up to leaf body)
    path.lineTo(center.dx, bottom);

    // Draw the left side of the leaf - exact LeafClipper logic
    path.quadraticBezierTo(
      left, // Control point X (0 in original)
      bottom - (height - stemLength) * 0.3, // Control point Y adjusted for stem
      center.dx, // End point X (size.width * 0.5 in original)
      top, // End point Y (0 in original - the tip of the leaf)
    );

    // Draw the right side of the leaf - exact LeafClipper logic
    path.quadraticBezierTo(
      right, // Control point X (size.width in original)
      bottom - (height - stemLength) * 0.3, // Control point Y adjusted for stem
      center.dx, // End point X (size.width / 2 in original)
      bottom, // End point Y (back to the leaf body bottom)
    );

    // Close the path back to stem bottom
    path.lineTo(center.dx, stemBottom);
    path.close();
    return path;
  }

  void _drawRevolvingDots(Canvas canvas, Offset center, double radius) {
    final isMobile = canvasSize.width < 600;
    final dotCount = isMobile ? 4 : 6;
    final dotRadius = isMobile ? 2.5 : 4.0;
    final rotationSpeed = pulseAnimation * 2 * math.pi;
    
    for (int i = 0; i < dotCount; i++) {
      final angle = (i * 2 * math.pi / dotCount) + rotationSpeed;
      final dotPosition = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      
      final dotPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(dotPosition, dotRadius, dotPaint);
      
      // Add glow effect to dots
      final glowPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
      
      canvas.drawCircle(dotPosition, dotRadius + 2, glowPaint);
    }
  }

  void _drawParticleEffects(Canvas canvas, Offset? nodePosition) {
    // Remove orbiting particle effects to prevent blinking
    // Only nodes should have pulse animation, not surrounding particles
    return;
  }

  Color _getNodeColor(GraphNode node) {
    if (node.isRoot || node.isLeaf) {
      return const Color(0xFF70e000); // Vibrant green for root and all leaf nodes
    } else {
      return const Color(0xFF38b000); // Keep the original green for branches
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class GraphVisualizationWidget extends StatefulWidget {
  final Map<int, List<GraphNode>> nodesByDepth;
  final GraphNode? selectedNode;
  final Function(GraphNode) onNodeTap;

  const GraphVisualizationWidget({
    super.key,
    required this.nodesByDepth,
    required this.selectedNode,
    required this.onNodeTap,
  });

  @override
  State<GraphVisualizationWidget> createState() => _GraphVisualizationWidgetState();
}

class _GraphVisualizationWidgetState extends State<GraphVisualizationWidget>
    with TickerProviderStateMixin {
  late AnimationController _selectionController;
  late AnimationController _pulseController;
  late AnimationController _connectionController;
  late Animation<double> _selectionAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _connectionAnimation;
  TransformationController? _transformationController;
  
  @override
  void initState() {
    super.initState();
    
    _selectionController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _selectionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _selectionController,
      curve: Curves.elasticOut,
    ));

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_pulseController);

    _connectionController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();
    _connectionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_connectionController);
    
    // Start animations if there's already a selected node on initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.selectedNode != null) {
        _selectionController.forward();
        _pulseController.repeat();
      }
    });
  }

  @override
  void didUpdateWidget(GraphVisualizationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedNode != widget.selectedNode) {
      _selectionController.reset();
      _selectionController.forward();
      
      // Only start pulse animation for selected node
      if (widget.selectedNode != null) {
        _pulseController.repeat();
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _selectionController.dispose();
    _pulseController.dispose();
    _connectionController.dispose();
    _transformationController?.dispose();
    super.dispose();
  }

  TransformationController _getInitialTransformation(BoxConstraints constraints, Size canvasSize) {
    if (_transformationController == null) {
      _transformationController = TransformationController();
      
      // Calculate the offset to center the root node in the viewport
      final viewportWidth = constraints.maxWidth;
      final viewportHeight = constraints.maxHeight;
      
      // Get the root node position (first node in the first depth level)
      final rootNodes = widget.nodesByDepth[0];
      double rootX = canvasSize.width / 2; // Default to center if no nodes
      double rootY = 100.0; // Position root node near the top with some padding
      
      if (rootNodes != null && rootNodes.isNotEmpty) {
        // Calculate positions to find where the root node is placed
        final positions = _calculateNodePositions(canvasSize);
        final rootNode = rootNodes.first;
        final position = positions[rootNode];
        
        if (position != null) {
          rootX = position.dx;
          rootY = position.dy;
        }
      }
      
      // Calculate the translation needed to center the root node
      final targetX = rootX - viewportWidth / 2;
      final targetY = rootY - viewportHeight / 2;
      
      _transformationController!.value = Matrix4.identity()
        ..translate(-targetX, -targetY);
    }
    
    return _transformationController!;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate canvas size for infinite scrolling plane
        Size canvasSize = _calculateCanvasSize(constraints);
        
        return InteractiveViewer(
          boundaryMargin: const EdgeInsets.all(double.infinity),
          minScale: 0.1,
          maxScale: 3.0,
          constrained: false,
          transformationController: _getInitialTransformation(constraints, canvasSize),
          child: SizedBox(
            width: canvasSize.width,
            height: canvasSize.height,
            child: GestureDetector(
              onTapDown: (details) {
                _handleTap(details.localPosition, canvasSize);
              },
              child: AnimatedBuilder(
                animation: widget.selectedNode != null 
                    ? Listenable.merge([_selectionAnimation, _pulseAnimation, _connectionAnimation])
                    : _connectionAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    size: canvasSize,
                    painter: AnimatedGraphPainter(
                      nodesByDepth: widget.nodesByDepth,
                      selectedNode: widget.selectedNode,
                      onNodeTap: widget.onNodeTap,
                      canvasSize: canvasSize,
                      selectionAnimation: _selectionAnimation.value,
                      pulseAnimation: widget.selectedNode != null ? _pulseAnimation.value : 0.0,
                      connectionAnimation: _connectionAnimation.value,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Size _calculateCanvasSize(BoxConstraints constraints) {
    // Create a much larger canvas for truly infinite feel
    const infiniteMultiplier = 10.0; // Make canvas 10x larger than viewport
    
    if (widget.nodesByDepth.isEmpty) {
      return Size(
        constraints.maxWidth * infiniteMultiplier, 
        constraints.maxHeight * infiniteMultiplier
      );
    }

    final isMobile = constraints.maxWidth < 600;
    final nodeRadius = isMobile ? 20.0 : 30.0;
    final horizontalSpacing = nodeRadius * 3.0;
    final verticalSpacing = isMobile ? 120.0 : 160.0;
    
    // Find maximum nodes in any depth level
    int maxNodesInDepth = 0;
    widget.nodesByDepth.forEach((depth, nodes) {
      if (nodes.length > maxNodesInDepth) {
        maxNodesInDepth = nodes.length;
      }
    });
    
    // Calculate required dimensions with much larger padding for infinite feel
    final maxDepth = widget.nodesByDepth.keys.isNotEmpty 
        ? widget.nodesByDepth.keys.reduce(math.max) 
        : 0;
    
    final requiredWidth = math.max(
      constraints.maxWidth * infiniteMultiplier,
      (maxNodesInDepth * horizontalSpacing) + (constraints.maxWidth * 4)
    );
    
    final requiredHeight = math.max(
      constraints.maxHeight * infiniteMultiplier,
      (maxDepth * verticalSpacing) + (constraints.maxHeight * 4)
    );
    
    return Size(requiredWidth, requiredHeight);
  }

  // Calculate node positions using the same logic as the AnimatedGraphPainter
  Map<GraphNode, Offset> _calculateNodePositions(Size size) {
    final Map<GraphNode, Offset> positions = {};
    
    if (widget.nodesByDepth.isEmpty) return positions;
    
    // Calculate responsive spacing
    final isMobile = size.width < 600;
    final verticalSpacing = isMobile ? 120.0 : 160.0;
    
    // Calculate subtree widths for all nodes
    final subtreeWidths = _calculateSubtreeWidths();
    
    // Find root nodes (nodes with no parents)
    final Set<GraphNode> allNodes = {};
    final Set<GraphNode> children = {};
    
    widget.nodesByDepth.values.forEach((nodes) {
      allNodes.addAll(nodes);
      nodes.forEach((node) {
        children.addAll(node.children);
      });
    });
    
    final List<GraphNode> rootNodes = allNodes.where((node) => !children.contains(node)).toList();
    
    // Position root nodes
    double currentX = 0.0;
    for (final root in rootNodes) {
      final rootWidth = subtreeWidths[root] ?? 0.0;
      _assignPositions(
        root,
        currentX + (rootWidth / 2), // Center the root in its allocated space
        100.0, // Top padding
        positions,
        subtreeWidths,
        verticalSpacing
      );
      currentX += rootWidth + 200.0; // Add extra spacing between root trees
    }
    
    return positions;
  }
  
  // Calculate the size of the subtree rooted at each node
  Map<GraphNode, double> _calculateSubtreeWidths() {
    final Map<GraphNode, double> subtreeWidths = {};
    
    // Process nodes from bottom to top
    final depths = widget.nodesByDepth.keys.toList()..sort((a, b) => b.compareTo(a));
    
    for (final depth in depths) {
      for (final node in widget.nodesByDepth[depth]!) {
        if (node.children.isEmpty) {
          // Leaf nodes have a fixed width
          subtreeWidths[node] = 100.0; // Base width for leaf nodes
        } else {
          // Calculate total width needed for children
          double totalWidth = 0.0;
          for (final child in node.children) {
            totalWidth += subtreeWidths[child] ?? 0.0;
          }
          // Add spacing between children
          if (node.children.length > 1) {
            totalWidth += (node.children.length - 1) * 40.0; // Spacing between children
          }
          subtreeWidths[node] = totalWidth;
        }
      }
    }
    
    return subtreeWidths;
  }

  // Assign x-positions to nodes using a depth-first traversal
  void _assignPositions(
    GraphNode node,
    double x,
    double y,
    Map<GraphNode, Offset> positions,
    Map<GraphNode, double> subtreeWidths,
    double verticalSpacing
  ) {
    // If we've already positioned this node, return
    if (positions.containsKey(node)) return;
    
    // Position the current node
    positions[node] = Offset(x, y);
    
    // If it's a leaf node, we're done
    if (node.children.isEmpty) return;
    
    // Calculate total width of all children
    double totalWidth = 0.0;
    for (final child in node.children) {
      totalWidth += subtreeWidths[child] ?? 0.0;
    }
    
    // Add spacing between children
    if (node.children.length > 1) {
      totalWidth += (node.children.length - 1) * 40.0; // Spacing between children
    }
    
    // Calculate starting x position to center children under parent
    double currentX = x - (totalWidth / 2);
    
    // Position each child
    for (final child in node.children) {
      final childWidth = subtreeWidths[child] ?? 0.0;
      _assignPositions(
        child,
        currentX + (childWidth / 2), // Center the child in its allocated space
        y + verticalSpacing,
        positions,
        subtreeWidths,
        verticalSpacing
      );
      currentX += childWidth + 40.0; // Move to next child position
    }
  }

  void _handleTap(Offset tapPosition, Size size) {
    // Calculate node positions using the same logic as the painter
    final nodePositions = _calculateNodePositions(size);
    
    // Check if tap is within any node's bounds with responsive size for leaf shape
    final isMobile = size.width < 600;
    final baseSize = isMobile ? 30.0 : 40.0; // Slightly larger tap target
    
    // Check nodes in reverse order to prioritize nodes that are drawn on top
    final nodes = nodePositions.entries.toList();
    for (int i = nodes.length - 1; i >= 0; i--) {
      final entry = nodes[i];
      final node = entry.key;
      final position = entry.value;
      
      // Calculate distance from tap to node center
      final dx = tapPosition.dx - position.dx;
      final dy = tapPosition.dy - position.dy;
      final distance = math.sqrt(dx * dx + dy * dy);
      
      // Use a slightly larger tap target for better touch accuracy
      if (distance <= baseSize) {
        widget.onNodeTap(node);
        return; // Stop after finding the first (topmost) node
      }
    }
  }
}
