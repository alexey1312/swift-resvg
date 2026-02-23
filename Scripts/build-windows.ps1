# Build resvg static libraries for Windows (x86_64 + aarch64 MSVC)
#
# Usage:
#   .\Scripts\build-windows.ps1                  # Build current version (0.45.1)
#   .\Scripts\build-windows.ps1 -ResvgVersion 0.46.0  # Build specific version
#
# Requirements:
#   - Rust toolchain with targets: x86_64-pc-windows-msvc, aarch64-pc-windows-msvc
#
# Outputs:
#   resvg.artifactbundle/windows-x86_64/resvg.lib      (SPM primary — no lib prefix for Windows)
#   resvg.artifactbundle/windows-x86_64/libresvg.lib   (compatibility copy)
#   resvg.artifactbundle/windows-aarch64/resvg.lib     (SPM primary — no lib prefix for Windows)
#   resvg.artifactbundle/windows-aarch64/libresvg.lib  (compatibility copy)

param(
    [string]$ResvgVersion = "0.45.1"
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$BuildDir = Join-Path $ProjectRoot ".resvg-build"
$BundleDir = Join-Path $ProjectRoot "resvg.artifactbundle"

Write-Host "=== Building resvg $ResvgVersion for Windows ==="

# Clean and clone resvg
if (Test-Path $BuildDir) {
    Remove-Item -Recurse -Force $BuildDir
}
New-Item -ItemType Directory -Path $BuildDir -Force | Out-Null

Write-Host "Cloning resvg v$ResvgVersion..."
git clone --depth 1 --branch "v$ResvgVersion" `
    https://github.com/RazrFalcon/resvg.git "$BuildDir\resvg"

#######################################
# Apply patch: Add SVG export functions
#######################################
Write-Host ""
Write-Host "=== Applying SVG export patch ==="

$RustPatch = @'

// =============================================================================
// SVG Export Functions (added by swift-resvg)
// =============================================================================

use std::ffi::CString;

/// Exports the render tree back to normalized SVG string.
///
/// The SVG is normalized by usvg with all defaults applied:
/// - Missing fill defaults to black
/// - CSS styles are resolved
/// - `<use>` references are expanded
/// - clip-path elements are resolved
///
/// Returns NULL on error. Must be freed via `resvg_svg_string_destroy`.
#[no_mangle]
pub extern "C" fn resvg_tree_to_svg(
    tree: *const resvg_render_tree,
    len: *mut usize,
) -> *mut std::os::raw::c_char {
    if tree.is_null() || len.is_null() {
        return std::ptr::null_mut();
    }

    let tree = unsafe { &*tree };
    let svg_string = tree.0.to_string(&usvg::WriteOptions::default());

    unsafe { *len = svg_string.len(); }

    match CString::new(svg_string) {
        Ok(cstr) => cstr.into_raw(),
        Err(_) => std::ptr::null_mut(),
    }
}

/// Frees SVG string allocated by `resvg_tree_to_svg`.
#[no_mangle]
pub extern "C" fn resvg_svg_string_destroy(svg: *mut std::os::raw::c_char) {
    if !svg.is_null() {
        unsafe { let _ = CString::from_raw(svg); }
    }
}

// =============================================================================
// Tree Traversal API (added by swift-resvg)
// =============================================================================

// -----------------------------------------------------------------------------
// Type Definitions
// -----------------------------------------------------------------------------

/// Node type enumeration
#[repr(C)]
#[derive(Copy, Clone, Debug, PartialEq)]
pub enum resvg_node_type {
    RESVG_NODE_GROUP = 0,
    RESVG_NODE_PATH = 1,
    RESVG_NODE_IMAGE = 2,
    RESVG_NODE_TEXT = 3,
}

/// Mask type enumeration
#[repr(C)]
#[derive(Copy, Clone, Debug, PartialEq)]
pub enum resvg_mask_type {
    RESVG_MASK_LUMINANCE = 0,
    RESVG_MASK_ALPHA = 1,
}

/// Paint type enumeration
#[repr(C)]
#[derive(Copy, Clone, Debug, PartialEq)]
pub enum resvg_paint_type {
    RESVG_PAINT_COLOR = 0,
    RESVG_PAINT_LINEAR_GRADIENT = 1,
    RESVG_PAINT_RADIAL_GRADIENT = 2,
    RESVG_PAINT_PATTERN = 3,
}

/// Fill rule enumeration
#[repr(C)]
#[derive(Copy, Clone, Debug, PartialEq)]
pub enum resvg_fill_rule {
    RESVG_FILL_NONZERO = 0,
    RESVG_FILL_EVENODD = 1,
}

/// Line cap enumeration
#[repr(C)]
#[derive(Copy, Clone, Debug, PartialEq)]
pub enum resvg_linecap {
    RESVG_LINECAP_BUTT = 0,
    RESVG_LINECAP_ROUND = 1,
    RESVG_LINECAP_SQUARE = 2,
}

/// Line join enumeration
#[repr(C)]
#[derive(Copy, Clone, Debug, PartialEq)]
pub enum resvg_linejoin {
    RESVG_LINEJOIN_MITER = 0,
    RESVG_LINEJOIN_ROUND = 1,
    RESVG_LINEJOIN_BEVEL = 2,
    RESVG_LINEJOIN_MITER_CLIP = 3,
}

/// Path segment type enumeration
#[repr(C)]
#[derive(Copy, Clone, Debug, PartialEq)]
pub enum resvg_path_segment_type {
    RESVG_PATH_SEG_MOVE_TO = 0,
    RESVG_PATH_SEG_LINE_TO = 1,
    RESVG_PATH_SEG_QUAD_TO = 2,
    RESVG_PATH_SEG_CUBIC_TO = 3,
    RESVG_PATH_SEG_CLOSE = 4,
}

/// Blend mode enumeration
#[repr(C)]
#[derive(Copy, Clone, Debug, PartialEq)]
pub enum resvg_blend_mode {
    RESVG_BLEND_NORMAL = 0,
    RESVG_BLEND_MULTIPLY = 1,
    RESVG_BLEND_SCREEN = 2,
    RESVG_BLEND_OVERLAY = 3,
    RESVG_BLEND_DARKEN = 4,
    RESVG_BLEND_LIGHTEN = 5,
    RESVG_BLEND_COLOR_DODGE = 6,
    RESVG_BLEND_COLOR_BURN = 7,
    RESVG_BLEND_HARD_LIGHT = 8,
    RESVG_BLEND_SOFT_LIGHT = 9,
    RESVG_BLEND_DIFFERENCE = 10,
    RESVG_BLEND_EXCLUSION = 11,
    RESVG_BLEND_HUE = 12,
    RESVG_BLEND_SATURATION = 13,
    RESVG_BLEND_COLOR = 14,
    RESVG_BLEND_LUMINOSITY = 15,
}

/// Spread method enumeration
#[repr(C)]
#[derive(Copy, Clone, Debug, PartialEq)]
pub enum resvg_spread_method {
    RESVG_SPREAD_PAD = 0,
    RESVG_SPREAD_REFLECT = 1,
    RESVG_SPREAD_REPEAT = 2,
}

/// Image kind enumeration
#[repr(C)]
#[derive(Copy, Clone, Debug, PartialEq)]
pub enum resvg_image_kind {
    RESVG_IMAGE_JPEG = 0,
    RESVG_IMAGE_PNG = 1,
    RESVG_IMAGE_GIF = 2,
    RESVG_IMAGE_SVG = 3,
}

/// RGBA color
#[repr(C)]
#[derive(Copy, Clone, Debug)]
pub struct resvg_color {
    pub r: u8,
    pub g: u8,
    pub b: u8,
    pub a: u8,
}

/// Gradient stop
#[repr(C)]
#[derive(Copy, Clone, Debug)]
pub struct resvg_gradient_stop {
    pub offset: f32,
    pub r: u8,
    pub g: u8,
    pub b: u8,
    pub a: u8,
}

/// Path segment
#[repr(C)]
#[derive(Copy, Clone, Debug)]
pub struct resvg_path_segment {
    pub seg_type: resvg_path_segment_type,
    pub x: f32,
    pub y: f32,
    pub x1: f32,
    pub y1: f32,
    pub x2: f32,
    pub y2: f32,
}

// -----------------------------------------------------------------------------
// Core Tree Traversal
// -----------------------------------------------------------------------------

/// Returns the root group of the render tree.
/// The returned pointer is valid as long as the tree is alive.
#[no_mangle]
pub extern "C" fn resvg_tree_root(tree: *const resvg_render_tree) -> *const usvg::Group {
    if tree.is_null() {
        return std::ptr::null();
    }
    let tree = unsafe { &*tree };
    tree.0.root() as *const usvg::Group
}

/// Returns the number of children in a group.
#[no_mangle]
pub extern "C" fn resvg_group_children_count(group: *const usvg::Group) -> usize {
    if group.is_null() {
        return 0;
    }
    let group = unsafe { &*group };
    group.children().len()
}

/// Returns a child node at the given index.
/// Returns NULL if index is out of bounds.
#[no_mangle]
pub extern "C" fn resvg_group_child_at(group: *const usvg::Group, index: usize) -> *const usvg::Node {
    if group.is_null() {
        return std::ptr::null();
    }
    let group = unsafe { &*group };
    group.children().get(index).map_or(std::ptr::null(), |n| n as *const usvg::Node)
}

/// Returns the type of a node.
#[no_mangle]
pub extern "C" fn resvg_node_get_type(node: *const usvg::Node) -> resvg_node_type {
    if node.is_null() {
        return resvg_node_type::RESVG_NODE_GROUP;
    }
    let node = unsafe { &*node };
    match node {
        usvg::Node::Group(_) => resvg_node_type::RESVG_NODE_GROUP,
        usvg::Node::Path(_) => resvg_node_type::RESVG_NODE_PATH,
        usvg::Node::Image(_) => resvg_node_type::RESVG_NODE_IMAGE,
        usvg::Node::Text(_) => resvg_node_type::RESVG_NODE_TEXT,
    }
}

/// Casts a node to a group. Returns NULL if the node is not a group.
#[no_mangle]
pub extern "C" fn resvg_node_as_group(node: *const usvg::Node) -> *const usvg::Group {
    if node.is_null() {
        return std::ptr::null();
    }
    let node = unsafe { &*node };
    match node {
        usvg::Node::Group(g) => g.as_ref() as *const usvg::Group,
        _ => std::ptr::null(),
    }
}

/// Casts a node to a path. Returns NULL if the node is not a path.
#[no_mangle]
pub extern "C" fn resvg_node_as_path(node: *const usvg::Node) -> *const usvg::Path {
    if node.is_null() {
        return std::ptr::null();
    }
    let node = unsafe { &*node };
    match node {
        usvg::Node::Path(p) => p.as_ref() as *const usvg::Path,
        _ => std::ptr::null(),
    }
}

/// Casts a node to an image. Returns NULL if the node is not an image.
#[no_mangle]
pub extern "C" fn resvg_node_as_image(node: *const usvg::Node) -> *const usvg::Image {
    if node.is_null() {
        return std::ptr::null();
    }
    let node = unsafe { &*node };
    match node {
        usvg::Node::Image(i) => i.as_ref() as *const usvg::Image,
        _ => std::ptr::null(),
    }
}

/// Casts a node to text. Returns NULL if the node is not text.
#[no_mangle]
pub extern "C" fn resvg_node_as_text(node: *const usvg::Node) -> *const usvg::Text {
    if node.is_null() {
        return std::ptr::null();
    }
    let node = unsafe { &*node };
    match node {
        usvg::Node::Text(t) => t.as_ref() as *const usvg::Text,
        _ => std::ptr::null(),
    }
}

// -----------------------------------------------------------------------------
// Group Properties
// -----------------------------------------------------------------------------

/// Returns the ID of a group. Returns the length in `len`.
/// The returned pointer is valid as long as the tree is alive.
#[no_mangle]
pub extern "C" fn resvg_group_id(group: *const usvg::Group, len: *mut usize) -> *const std::os::raw::c_char {
    if group.is_null() || len.is_null() {
        return std::ptr::null();
    }
    let group = unsafe { &*group };
    let id = group.id();
    unsafe { *len = id.len(); }
    id.as_ptr() as *const std::os::raw::c_char
}

/// Returns the relative transform of a group.
#[no_mangle]
pub extern "C" fn resvg_group_transform(group: *const usvg::Group) -> resvg_transform {
    if group.is_null() {
        return resvg_transform { a: 1.0, b: 0.0, c: 0.0, d: 1.0, e: 0.0, f: 0.0 };
    }
    let group = unsafe { &*group };
    let t = group.transform();
    resvg_transform { a: t.sx, b: t.ky, c: t.kx, d: t.sy, e: t.tx, f: t.ty }
}

/// Returns the absolute transform of a group (including all ancestors).
#[no_mangle]
pub extern "C" fn resvg_group_abs_transform(group: *const usvg::Group) -> resvg_transform {
    if group.is_null() {
        return resvg_transform { a: 1.0, b: 0.0, c: 0.0, d: 1.0, e: 0.0, f: 0.0 };
    }
    let group = unsafe { &*group };
    let t = group.abs_transform();
    resvg_transform { a: t.sx, b: t.ky, c: t.kx, d: t.sy, e: t.tx, f: t.ty }
}

/// Returns the opacity of a group.
#[no_mangle]
pub extern "C" fn resvg_group_opacity(group: *const usvg::Group) -> f32 {
    if group.is_null() {
        return 1.0;
    }
    let group = unsafe { &*group };
    group.opacity().get()
}

/// Returns the blend mode of a group.
#[no_mangle]
pub extern "C" fn resvg_group_blend_mode(group: *const usvg::Group) -> resvg_blend_mode {
    if group.is_null() {
        return resvg_blend_mode::RESVG_BLEND_NORMAL;
    }
    let group = unsafe { &*group };
    match group.blend_mode() {
        usvg::BlendMode::Normal => resvg_blend_mode::RESVG_BLEND_NORMAL,
        usvg::BlendMode::Multiply => resvg_blend_mode::RESVG_BLEND_MULTIPLY,
        usvg::BlendMode::Screen => resvg_blend_mode::RESVG_BLEND_SCREEN,
        usvg::BlendMode::Overlay => resvg_blend_mode::RESVG_BLEND_OVERLAY,
        usvg::BlendMode::Darken => resvg_blend_mode::RESVG_BLEND_DARKEN,
        usvg::BlendMode::Lighten => resvg_blend_mode::RESVG_BLEND_LIGHTEN,
        usvg::BlendMode::ColorDodge => resvg_blend_mode::RESVG_BLEND_COLOR_DODGE,
        usvg::BlendMode::ColorBurn => resvg_blend_mode::RESVG_BLEND_COLOR_BURN,
        usvg::BlendMode::HardLight => resvg_blend_mode::RESVG_BLEND_HARD_LIGHT,
        usvg::BlendMode::SoftLight => resvg_blend_mode::RESVG_BLEND_SOFT_LIGHT,
        usvg::BlendMode::Difference => resvg_blend_mode::RESVG_BLEND_DIFFERENCE,
        usvg::BlendMode::Exclusion => resvg_blend_mode::RESVG_BLEND_EXCLUSION,
        usvg::BlendMode::Hue => resvg_blend_mode::RESVG_BLEND_HUE,
        usvg::BlendMode::Saturation => resvg_blend_mode::RESVG_BLEND_SATURATION,
        usvg::BlendMode::Color => resvg_blend_mode::RESVG_BLEND_COLOR,
        usvg::BlendMode::Luminosity => resvg_blend_mode::RESVG_BLEND_LUMINOSITY,
    }
}

/// Returns true if the group has a mask.
#[no_mangle]
pub extern "C" fn resvg_group_has_mask(group: *const usvg::Group) -> bool {
    if group.is_null() {
        return false;
    }
    let group = unsafe { &*group };
    group.mask().is_some()
}

/// Returns true if the group has a clip path.
#[no_mangle]
pub extern "C" fn resvg_group_has_clip_path(group: *const usvg::Group) -> bool {
    if group.is_null() {
        return false;
    }
    let group = unsafe { &*group };
    group.clip_path().is_some()
}

/// Returns true if the group is isolated.
#[no_mangle]
pub extern "C" fn resvg_group_isolate(group: *const usvg::Group) -> bool {
    if group.is_null() {
        return false;
    }
    let group = unsafe { &*group };
    group.isolate()
}

// -----------------------------------------------------------------------------
// Mask Access
// -----------------------------------------------------------------------------

/// Returns the mask of a group. Returns NULL if the group has no mask.
#[no_mangle]
pub extern "C" fn resvg_group_mask(group: *const usvg::Group) -> *const usvg::Mask {
    if group.is_null() {
        return std::ptr::null();
    }
    let group = unsafe { &*group };
    group.mask().map_or(std::ptr::null(), |m| m as *const usvg::Mask)
}

/// Returns the ID of a mask.
#[no_mangle]
pub extern "C" fn resvg_mask_id(mask: *const usvg::Mask, len: *mut usize) -> *const std::os::raw::c_char {
    if mask.is_null() || len.is_null() {
        return std::ptr::null();
    }
    let mask = unsafe { &*mask };
    let id = mask.id();
    unsafe { *len = id.len(); }
    id.as_ptr() as *const std::os::raw::c_char
}

/// Returns the bounding rect of a mask.
#[no_mangle]
pub extern "C" fn resvg_mask_rect(mask: *const usvg::Mask) -> resvg_rect {
    if mask.is_null() {
        return resvg_rect { x: 0.0, y: 0.0, width: 0.0, height: 0.0 };
    }
    let mask = unsafe { &*mask };
    let r = mask.rect();
    resvg_rect { x: r.x(), y: r.y(), width: r.width(), height: r.height() }
}

/// Returns the type of a mask (luminance or alpha).
#[no_mangle]
pub extern "C" fn resvg_mask_kind(mask: *const usvg::Mask) -> resvg_mask_type {
    if mask.is_null() {
        return resvg_mask_type::RESVG_MASK_LUMINANCE;
    }
    let mask = unsafe { &*mask };
    match mask.kind() {
        usvg::MaskType::Luminance => resvg_mask_type::RESVG_MASK_LUMINANCE,
        usvg::MaskType::Alpha => resvg_mask_type::RESVG_MASK_ALPHA,
    }
}

/// Returns the root group of a mask's content.
#[no_mangle]
pub extern "C" fn resvg_mask_root(mask: *const usvg::Mask) -> *const usvg::Group {
    if mask.is_null() {
        return std::ptr::null();
    }
    let mask = unsafe { &*mask };
    mask.root() as *const usvg::Group
}

/// Returns the nested mask of a mask. Returns NULL if there is no nested mask.
#[no_mangle]
pub extern "C" fn resvg_mask_mask(mask: *const usvg::Mask) -> *const usvg::Mask {
    if mask.is_null() {
        return std::ptr::null();
    }
    let mask = unsafe { &*mask };
    mask.mask().map_or(std::ptr::null(), |m| m as *const usvg::Mask)
}

// -----------------------------------------------------------------------------
// Clip Path Access
// -----------------------------------------------------------------------------

/// Returns the clip path of a group. Returns NULL if the group has no clip path.
#[no_mangle]
pub extern "C" fn resvg_group_clip_path(group: *const usvg::Group) -> *const usvg::ClipPath {
    if group.is_null() {
        return std::ptr::null();
    }
    let group = unsafe { &*group };
    group.clip_path().map_or(std::ptr::null(), |c| c as *const usvg::ClipPath)
}

/// Returns the ID of a clip path.
#[no_mangle]
pub extern "C" fn resvg_clip_path_id(clip: *const usvg::ClipPath, len: *mut usize) -> *const std::os::raw::c_char {
    if clip.is_null() || len.is_null() {
        return std::ptr::null();
    }
    let clip = unsafe { &*clip };
    let id = clip.id();
    unsafe { *len = id.len(); }
    id.as_ptr() as *const std::os::raw::c_char
}

/// Returns the transform of a clip path.
#[no_mangle]
pub extern "C" fn resvg_clip_path_transform(clip: *const usvg::ClipPath) -> resvg_transform {
    if clip.is_null() {
        return resvg_transform { a: 1.0, b: 0.0, c: 0.0, d: 1.0, e: 0.0, f: 0.0 };
    }
    let clip = unsafe { &*clip };
    let t = clip.transform();
    resvg_transform { a: t.sx, b: t.ky, c: t.kx, d: t.sy, e: t.tx, f: t.ty }
}

/// Returns the root group of a clip path's content.
#[no_mangle]
pub extern "C" fn resvg_clip_path_root(clip: *const usvg::ClipPath) -> *const usvg::Group {
    if clip.is_null() {
        return std::ptr::null();
    }
    let clip = unsafe { &*clip };
    clip.root() as *const usvg::Group
}

// -----------------------------------------------------------------------------
// Path Properties
// -----------------------------------------------------------------------------

/// Returns the ID of a path.
#[no_mangle]
pub extern "C" fn resvg_path_id(path: *const usvg::Path, len: *mut usize) -> *const std::os::raw::c_char {
    if path.is_null() || len.is_null() {
        return std::ptr::null();
    }
    let path = unsafe { &*path };
    let id = path.id();
    unsafe { *len = id.len(); }
    id.as_ptr() as *const std::os::raw::c_char
}

/// Returns the transform of a path (same as abs_transform for paths).
#[no_mangle]
pub extern "C" fn resvg_path_transform(path: *const usvg::Path) -> resvg_transform {
    if path.is_null() {
        return resvg_transform { a: 1.0, b: 0.0, c: 0.0, d: 1.0, e: 0.0, f: 0.0 };
    }
    let path = unsafe { &*path };
    let t = path.abs_transform();
    resvg_transform { a: t.sx, b: t.ky, c: t.kx, d: t.sy, e: t.tx, f: t.ty }
}

/// Returns the absolute transform of a path.
#[no_mangle]
pub extern "C" fn resvg_path_abs_transform(path: *const usvg::Path) -> resvg_transform {
    if path.is_null() {
        return resvg_transform { a: 1.0, b: 0.0, c: 0.0, d: 1.0, e: 0.0, f: 0.0 };
    }
    let path = unsafe { &*path };
    let t = path.abs_transform();
    resvg_transform { a: t.sx, b: t.ky, c: t.kx, d: t.sy, e: t.tx, f: t.ty }
}

/// Returns true if the path is visible.
#[no_mangle]
pub extern "C" fn resvg_path_is_visible(path: *const usvg::Path) -> bool {
    if path.is_null() {
        return false;
    }
    let path = unsafe { &*path };
    path.is_visible()
}

/// Returns the number of segments in a path's data.
#[no_mangle]
pub extern "C" fn resvg_path_data_len(path: *const usvg::Path) -> usize {
    if path.is_null() {
        return 0;
    }
    let path = unsafe { &*path };
    path.data().verbs().len()
}

/// Returns a path segment at the given index.
/// Returns false if the index is out of bounds.
#[no_mangle]
pub extern "C" fn resvg_path_data_segment(
    path: *const usvg::Path,
    index: usize,
    segment: *mut resvg_path_segment,
) -> bool {
    if path.is_null() || segment.is_null() {
        return false;
    }
    let path = unsafe { &*path };
    let data = path.data();
    let verbs = data.verbs();
    let points = data.points();

    if index >= verbs.len() {
        return false;
    }

    // tiny-skia PathVerb: Move=0, Line=1, Quad=2, Cubic=3, Close=4
    // Points per verb: Move=1, Line=1, Quad=2, Cubic=3, Close=0
    fn verb_to_u8(v: &impl std::fmt::Debug) -> u8 {
        let s = format!("{:?}", v);
        // tiny-skia uses "Move", "Line", etc. not "MoveTo", "LineTo"
        if s.starts_with("Move") { 0 }
        else if s.starts_with("Line") { 1 }
        else if s.starts_with("Quad") { 2 }
        else if s.starts_with("Cubic") { 3 }
        else { 4 } // Close
    }

    fn points_for_verb(verb: u8) -> usize {
        match verb {
            0 => 1, // MoveTo
            1 => 1, // LineTo
            2 => 2, // QuadTo
            3 => 3, // CubicTo
            _ => 0, // Close
        }
    }

    // Calculate point offset for this segment
    let mut point_offset = 0usize;
    for i in 0..index {
        point_offset += points_for_verb(verb_to_u8(&verbs[i]));
    }

    let seg = unsafe { &mut *segment };
    let verb = verb_to_u8(&verbs[index]);

    match verb {
        0 => { // MoveTo
            let p = points[point_offset];
            *seg = resvg_path_segment {
                seg_type: resvg_path_segment_type::RESVG_PATH_SEG_MOVE_TO,
                x: p.x, y: p.y,
                x1: 0.0, y1: 0.0, x2: 0.0, y2: 0.0,
            };
        }
        1 => { // LineTo
            let p = points[point_offset];
            *seg = resvg_path_segment {
                seg_type: resvg_path_segment_type::RESVG_PATH_SEG_LINE_TO,
                x: p.x, y: p.y,
                x1: 0.0, y1: 0.0, x2: 0.0, y2: 0.0,
            };
        }
        2 => { // QuadTo
            let p1 = points[point_offset];
            let p2 = points[point_offset + 1];
            *seg = resvg_path_segment {
                seg_type: resvg_path_segment_type::RESVG_PATH_SEG_QUAD_TO,
                x: p2.x, y: p2.y,
                x1: p1.x, y1: p1.y,
                x2: 0.0, y2: 0.0,
            };
        }
        3 => { // CubicTo
            let p1 = points[point_offset];
            let p2 = points[point_offset + 1];
            let p3 = points[point_offset + 2];
            *seg = resvg_path_segment {
                seg_type: resvg_path_segment_type::RESVG_PATH_SEG_CUBIC_TO,
                x: p3.x, y: p3.y,
                x1: p1.x, y1: p1.y,
                x2: p2.x, y2: p2.y,
            };
        }
        _ => { // Close
            *seg = resvg_path_segment {
                seg_type: resvg_path_segment_type::RESVG_PATH_SEG_CLOSE,
                x: 0.0, y: 0.0,
                x1: 0.0, y1: 0.0, x2: 0.0, y2: 0.0,
            };
        }
    }
    true
}

/// Returns true if the path has a fill.
#[no_mangle]
pub extern "C" fn resvg_path_has_fill(path: *const usvg::Path) -> bool {
    if path.is_null() {
        return false;
    }
    let path = unsafe { &*path };
    path.fill().is_some()
}

/// Returns true if the path has a stroke.
#[no_mangle]
pub extern "C" fn resvg_path_has_stroke(path: *const usvg::Path) -> bool {
    if path.is_null() {
        return false;
    }
    let path = unsafe { &*path };
    path.stroke().is_some()
}

/// Returns the fill of a path. Returns NULL if the path has no fill.
#[no_mangle]
pub extern "C" fn resvg_path_fill(path: *const usvg::Path) -> *const usvg::Fill {
    if path.is_null() {
        return std::ptr::null();
    }
    let path = unsafe { &*path };
    path.fill().map_or(std::ptr::null(), |f| f as *const usvg::Fill)
}

/// Returns the stroke of a path. Returns NULL if the path has no stroke.
#[no_mangle]
pub extern "C" fn resvg_path_stroke(path: *const usvg::Path) -> *const usvg::Stroke {
    if path.is_null() {
        return std::ptr::null();
    }
    let path = unsafe { &*path };
    path.stroke().map_or(std::ptr::null(), |s| s as *const usvg::Stroke)
}

// -----------------------------------------------------------------------------
// Fill Properties
// -----------------------------------------------------------------------------

/// Returns the paint type of a fill.
#[no_mangle]
pub extern "C" fn resvg_fill_paint_type(fill: *const usvg::Fill) -> resvg_paint_type {
    if fill.is_null() {
        return resvg_paint_type::RESVG_PAINT_COLOR;
    }
    let fill = unsafe { &*fill };
    match &fill.paint() {
        usvg::Paint::Color(_) => resvg_paint_type::RESVG_PAINT_COLOR,
        usvg::Paint::LinearGradient(_) => resvg_paint_type::RESVG_PAINT_LINEAR_GRADIENT,
        usvg::Paint::RadialGradient(_) => resvg_paint_type::RESVG_PAINT_RADIAL_GRADIENT,
        usvg::Paint::Pattern(_) => resvg_paint_type::RESVG_PAINT_PATTERN,
    }
}

/// Returns the color of a fill (if it's a solid color).
#[no_mangle]
pub extern "C" fn resvg_fill_color(fill: *const usvg::Fill) -> resvg_color {
    if fill.is_null() {
        return resvg_color { r: 0, g: 0, b: 0, a: 255 };
    }
    let fill = unsafe { &*fill };
    match fill.paint() {
        usvg::Paint::Color(c) => resvg_color { r: c.red, g: c.green, b: c.blue, a: 255 },
        _ => resvg_color { r: 0, g: 0, b: 0, a: 255 },
    }
}

/// Returns the opacity of a fill.
#[no_mangle]
pub extern "C" fn resvg_fill_opacity(fill: *const usvg::Fill) -> f32 {
    if fill.is_null() {
        return 1.0;
    }
    let fill = unsafe { &*fill };
    fill.opacity().get()
}

/// Returns the fill rule.
#[no_mangle]
pub extern "C" fn resvg_fill_get_rule(fill: *const usvg::Fill) -> resvg_fill_rule {
    if fill.is_null() {
        return resvg_fill_rule::RESVG_FILL_NONZERO;
    }
    let fill = unsafe { &*fill };
    match fill.rule() {
        usvg::FillRule::NonZero => resvg_fill_rule::RESVG_FILL_NONZERO,
        usvg::FillRule::EvenOdd => resvg_fill_rule::RESVG_FILL_EVENODD,
    }
}

/// Returns the linear gradient of a fill. Returns NULL if not a linear gradient.
#[no_mangle]
pub extern "C" fn resvg_fill_linear_gradient(fill: *const usvg::Fill) -> *const usvg::LinearGradient {
    if fill.is_null() {
        return std::ptr::null();
    }
    let fill = unsafe { &*fill };
    match fill.paint() {
        usvg::Paint::LinearGradient(lg) => &**lg as *const usvg::LinearGradient,
        _ => std::ptr::null(),
    }
}

/// Returns the radial gradient of a fill. Returns NULL if not a radial gradient.
#[no_mangle]
pub extern "C" fn resvg_fill_radial_gradient(fill: *const usvg::Fill) -> *const usvg::RadialGradient {
    if fill.is_null() {
        return std::ptr::null();
    }
    let fill = unsafe { &*fill };
    match fill.paint() {
        usvg::Paint::RadialGradient(rg) => &**rg as *const usvg::RadialGradient,
        _ => std::ptr::null(),
    }
}

// -----------------------------------------------------------------------------
// Stroke Properties
// -----------------------------------------------------------------------------

/// Returns the paint type of a stroke.
#[no_mangle]
pub extern "C" fn resvg_stroke_paint_type(stroke: *const usvg::Stroke) -> resvg_paint_type {
    if stroke.is_null() {
        return resvg_paint_type::RESVG_PAINT_COLOR;
    }
    let stroke = unsafe { &*stroke };
    match &stroke.paint() {
        usvg::Paint::Color(_) => resvg_paint_type::RESVG_PAINT_COLOR,
        usvg::Paint::LinearGradient(_) => resvg_paint_type::RESVG_PAINT_LINEAR_GRADIENT,
        usvg::Paint::RadialGradient(_) => resvg_paint_type::RESVG_PAINT_RADIAL_GRADIENT,
        usvg::Paint::Pattern(_) => resvg_paint_type::RESVG_PAINT_PATTERN,
    }
}

/// Returns the color of a stroke (if it's a solid color).
#[no_mangle]
pub extern "C" fn resvg_stroke_color(stroke: *const usvg::Stroke) -> resvg_color {
    if stroke.is_null() {
        return resvg_color { r: 0, g: 0, b: 0, a: 255 };
    }
    let stroke = unsafe { &*stroke };
    match stroke.paint() {
        usvg::Paint::Color(c) => resvg_color { r: c.red, g: c.green, b: c.blue, a: 255 },
        _ => resvg_color { r: 0, g: 0, b: 0, a: 255 },
    }
}

/// Returns the opacity of a stroke.
#[no_mangle]
pub extern "C" fn resvg_stroke_opacity(stroke: *const usvg::Stroke) -> f32 {
    if stroke.is_null() {
        return 1.0;
    }
    let stroke = unsafe { &*stroke };
    stroke.opacity().get()
}

/// Returns the width of a stroke.
#[no_mangle]
pub extern "C" fn resvg_stroke_width(stroke: *const usvg::Stroke) -> f32 {
    if stroke.is_null() {
        return 1.0;
    }
    let stroke = unsafe { &*stroke };
    stroke.width().get()
}

/// Returns the line cap of a stroke.
#[no_mangle]
pub extern "C" fn resvg_stroke_linecap(stroke: *const usvg::Stroke) -> resvg_linecap {
    if stroke.is_null() {
        return resvg_linecap::RESVG_LINECAP_BUTT;
    }
    let stroke = unsafe { &*stroke };
    match stroke.linecap() {
        usvg::LineCap::Butt => resvg_linecap::RESVG_LINECAP_BUTT,
        usvg::LineCap::Round => resvg_linecap::RESVG_LINECAP_ROUND,
        usvg::LineCap::Square => resvg_linecap::RESVG_LINECAP_SQUARE,
    }
}

/// Returns the line join of a stroke.
#[no_mangle]
pub extern "C" fn resvg_stroke_linejoin(stroke: *const usvg::Stroke) -> resvg_linejoin {
    if stroke.is_null() {
        return resvg_linejoin::RESVG_LINEJOIN_MITER;
    }
    let stroke = unsafe { &*stroke };
    match stroke.linejoin() {
        usvg::LineJoin::Miter => resvg_linejoin::RESVG_LINEJOIN_MITER,
        usvg::LineJoin::MiterClip => resvg_linejoin::RESVG_LINEJOIN_MITER_CLIP,
        usvg::LineJoin::Round => resvg_linejoin::RESVG_LINEJOIN_ROUND,
        usvg::LineJoin::Bevel => resvg_linejoin::RESVG_LINEJOIN_BEVEL,
    }
}

/// Returns the miter limit of a stroke.
#[no_mangle]
pub extern "C" fn resvg_stroke_miter_limit(stroke: *const usvg::Stroke) -> f32 {
    if stroke.is_null() {
        return 4.0;
    }
    let stroke = unsafe { &*stroke };
    stroke.miterlimit().get()
}

/// Returns the number of dash values in a stroke.
#[no_mangle]
pub extern "C" fn resvg_stroke_dasharray_len(stroke: *const usvg::Stroke) -> usize {
    if stroke.is_null() {
        return 0;
    }
    let stroke = unsafe { &*stroke };
    stroke.dasharray().map_or(0, |d| d.len())
}

/// Returns a dash value at the given index.
#[no_mangle]
pub extern "C" fn resvg_stroke_dasharray_at(stroke: *const usvg::Stroke, index: usize) -> f32 {
    if stroke.is_null() {
        return 0.0;
    }
    let stroke = unsafe { &*stroke };
    stroke.dasharray().and_then(|d| d.get(index).copied()).unwrap_or(0.0)
}

/// Returns the dash offset of a stroke.
#[no_mangle]
pub extern "C" fn resvg_stroke_dashoffset(stroke: *const usvg::Stroke) -> f32 {
    if stroke.is_null() {
        return 0.0;
    }
    let stroke = unsafe { &*stroke };
    stroke.dashoffset()
}

/// Returns the linear gradient of a stroke. Returns NULL if not a linear gradient.
#[no_mangle]
pub extern "C" fn resvg_stroke_linear_gradient(stroke: *const usvg::Stroke) -> *const usvg::LinearGradient {
    if stroke.is_null() {
        return std::ptr::null();
    }
    let stroke = unsafe { &*stroke };
    match stroke.paint() {
        usvg::Paint::LinearGradient(lg) => &**lg as *const usvg::LinearGradient,
        _ => std::ptr::null(),
    }
}

/// Returns the radial gradient of a stroke. Returns NULL if not a radial gradient.
#[no_mangle]
pub extern "C" fn resvg_stroke_radial_gradient(stroke: *const usvg::Stroke) -> *const usvg::RadialGradient {
    if stroke.is_null() {
        return std::ptr::null();
    }
    let stroke = unsafe { &*stroke };
    match stroke.paint() {
        usvg::Paint::RadialGradient(rg) => &**rg as *const usvg::RadialGradient,
        _ => std::ptr::null(),
    }
}

// -----------------------------------------------------------------------------
// Linear Gradient
// -----------------------------------------------------------------------------

/// Returns the ID of a linear gradient.
#[no_mangle]
pub extern "C" fn resvg_linear_gradient_id(lg: *const usvg::LinearGradient, len: *mut usize) -> *const std::os::raw::c_char {
    if lg.is_null() || len.is_null() {
        return std::ptr::null();
    }
    let lg = unsafe { &*lg };
    let id = lg.id();
    unsafe { *len = id.len(); }
    id.as_ptr() as *const std::os::raw::c_char
}

/// Returns the x1 coordinate of a linear gradient.
#[no_mangle]
pub extern "C" fn resvg_linear_gradient_x1(lg: *const usvg::LinearGradient) -> f32 {
    if lg.is_null() { return 0.0; }
    let lg = unsafe { &*lg };
    lg.x1()
}

/// Returns the y1 coordinate of a linear gradient.
#[no_mangle]
pub extern "C" fn resvg_linear_gradient_y1(lg: *const usvg::LinearGradient) -> f32 {
    if lg.is_null() { return 0.0; }
    let lg = unsafe { &*lg };
    lg.y1()
}

/// Returns the x2 coordinate of a linear gradient.
#[no_mangle]
pub extern "C" fn resvg_linear_gradient_x2(lg: *const usvg::LinearGradient) -> f32 {
    if lg.is_null() { return 0.0; }
    let lg = unsafe { &*lg };
    lg.x2()
}

/// Returns the y2 coordinate of a linear gradient.
#[no_mangle]
pub extern "C" fn resvg_linear_gradient_y2(lg: *const usvg::LinearGradient) -> f32 {
    if lg.is_null() { return 0.0; }
    let lg = unsafe { &*lg };
    lg.y2()
}

/// Returns the transform of a linear gradient.
#[no_mangle]
pub extern "C" fn resvg_linear_gradient_transform(lg: *const usvg::LinearGradient) -> resvg_transform {
    if lg.is_null() {
        return resvg_transform { a: 1.0, b: 0.0, c: 0.0, d: 1.0, e: 0.0, f: 0.0 };
    }
    let lg = unsafe { &*lg };
    let t = lg.transform();
    resvg_transform { a: t.sx, b: t.ky, c: t.kx, d: t.sy, e: t.tx, f: t.ty }
}

/// Returns the spread method of a linear gradient.
#[no_mangle]
pub extern "C" fn resvg_linear_gradient_spread_method(lg: *const usvg::LinearGradient) -> resvg_spread_method {
    if lg.is_null() {
        return resvg_spread_method::RESVG_SPREAD_PAD;
    }
    let lg = unsafe { &*lg };
    match lg.spread_method() {
        usvg::SpreadMethod::Pad => resvg_spread_method::RESVG_SPREAD_PAD,
        usvg::SpreadMethod::Reflect => resvg_spread_method::RESVG_SPREAD_REFLECT,
        usvg::SpreadMethod::Repeat => resvg_spread_method::RESVG_SPREAD_REPEAT,
    }
}

/// Returns the number of stops in a linear gradient.
#[no_mangle]
pub extern "C" fn resvg_linear_gradient_stops_count(lg: *const usvg::LinearGradient) -> usize {
    if lg.is_null() { return 0; }
    let lg = unsafe { &*lg };
    lg.stops().len()
}

/// Returns a stop at the given index.
#[no_mangle]
pub extern "C" fn resvg_linear_gradient_stop_at(
    lg: *const usvg::LinearGradient,
    index: usize,
    stop: *mut resvg_gradient_stop,
) -> bool {
    if lg.is_null() || stop.is_null() {
        return false;
    }
    let lg = unsafe { &*lg };
    let stops = lg.stops();
    if index >= stops.len() {
        return false;
    }
    let s = &stops[index];
    unsafe {
        *stop = resvg_gradient_stop {
            offset: s.offset().get(),
            r: s.color().red,
            g: s.color().green,
            b: s.color().blue,
            a: s.opacity().to_u8(),
        };
    }
    true
}

// -----------------------------------------------------------------------------
// Radial Gradient
// -----------------------------------------------------------------------------

/// Returns the ID of a radial gradient.
#[no_mangle]
pub extern "C" fn resvg_radial_gradient_id(rg: *const usvg::RadialGradient, len: *mut usize) -> *const std::os::raw::c_char {
    if rg.is_null() || len.is_null() {
        return std::ptr::null();
    }
    let rg = unsafe { &*rg };
    let id = rg.id();
    unsafe { *len = id.len(); }
    id.as_ptr() as *const std::os::raw::c_char
}

/// Returns the cx coordinate of a radial gradient.
#[no_mangle]
pub extern "C" fn resvg_radial_gradient_cx(rg: *const usvg::RadialGradient) -> f32 {
    if rg.is_null() { return 0.0; }
    let rg = unsafe { &*rg };
    rg.cx()
}

/// Returns the cy coordinate of a radial gradient.
#[no_mangle]
pub extern "C" fn resvg_radial_gradient_cy(rg: *const usvg::RadialGradient) -> f32 {
    if rg.is_null() { return 0.0; }
    let rg = unsafe { &*rg };
    rg.cy()
}

/// Returns the radius of a radial gradient.
#[no_mangle]
pub extern "C" fn resvg_radial_gradient_r(rg: *const usvg::RadialGradient) -> f32 {
    if rg.is_null() { return 0.0; }
    let rg = unsafe { &*rg };
    rg.r().get()
}

/// Returns the fx coordinate of a radial gradient.
#[no_mangle]
pub extern "C" fn resvg_radial_gradient_fx(rg: *const usvg::RadialGradient) -> f32 {
    if rg.is_null() { return 0.0; }
    let rg = unsafe { &*rg };
    rg.fx()
}

/// Returns the fy coordinate of a radial gradient.
#[no_mangle]
pub extern "C" fn resvg_radial_gradient_fy(rg: *const usvg::RadialGradient) -> f32 {
    if rg.is_null() { return 0.0; }
    let rg = unsafe { &*rg };
    rg.fy()
}

/// Returns the transform of a radial gradient.
#[no_mangle]
pub extern "C" fn resvg_radial_gradient_transform(rg: *const usvg::RadialGradient) -> resvg_transform {
    if rg.is_null() {
        return resvg_transform { a: 1.0, b: 0.0, c: 0.0, d: 1.0, e: 0.0, f: 0.0 };
    }
    let rg = unsafe { &*rg };
    let t = rg.transform();
    resvg_transform { a: t.sx, b: t.ky, c: t.kx, d: t.sy, e: t.tx, f: t.ty }
}

/// Returns the spread method of a radial gradient.
#[no_mangle]
pub extern "C" fn resvg_radial_gradient_spread_method(rg: *const usvg::RadialGradient) -> resvg_spread_method {
    if rg.is_null() {
        return resvg_spread_method::RESVG_SPREAD_PAD;
    }
    let rg = unsafe { &*rg };
    match rg.spread_method() {
        usvg::SpreadMethod::Pad => resvg_spread_method::RESVG_SPREAD_PAD,
        usvg::SpreadMethod::Reflect => resvg_spread_method::RESVG_SPREAD_REFLECT,
        usvg::SpreadMethod::Repeat => resvg_spread_method::RESVG_SPREAD_REPEAT,
    }
}

/// Returns the number of stops in a radial gradient.
#[no_mangle]
pub extern "C" fn resvg_radial_gradient_stops_count(rg: *const usvg::RadialGradient) -> usize {
    if rg.is_null() { return 0; }
    let rg = unsafe { &*rg };
    rg.stops().len()
}

/// Returns a stop at the given index.
#[no_mangle]
pub extern "C" fn resvg_radial_gradient_stop_at(
    rg: *const usvg::RadialGradient,
    index: usize,
    stop: *mut resvg_gradient_stop,
) -> bool {
    if rg.is_null() || stop.is_null() {
        return false;
    }
    let rg = unsafe { &*rg };
    let stops = rg.stops();
    if index >= stops.len() {
        return false;
    }
    let s = &stops[index];
    unsafe {
        *stop = resvg_gradient_stop {
            offset: s.offset().get(),
            r: s.color().red,
            g: s.color().green,
            b: s.color().blue,
            a: s.opacity().to_u8(),
        };
    }
    true
}

// -----------------------------------------------------------------------------
// Image Node
// -----------------------------------------------------------------------------

/// Returns the ID of an image.
#[no_mangle]
pub extern "C" fn resvg_image_id(image: *const usvg::Image, len: *mut usize) -> *const std::os::raw::c_char {
    if image.is_null() || len.is_null() {
        return std::ptr::null();
    }
    let image = unsafe { &*image };
    let id = image.id();
    unsafe { *len = id.len(); }
    id.as_ptr() as *const std::os::raw::c_char
}

/// Returns the transform of an image (same as abs_transform for images).
#[no_mangle]
pub extern "C" fn resvg_image_transform(image: *const usvg::Image) -> resvg_transform {
    if image.is_null() {
        return resvg_transform { a: 1.0, b: 0.0, c: 0.0, d: 1.0, e: 0.0, f: 0.0 };
    }
    let image = unsafe { &*image };
    let t = image.abs_transform();
    resvg_transform { a: t.sx, b: t.ky, c: t.kx, d: t.sy, e: t.tx, f: t.ty }
}

/// Returns the absolute transform of an image.
#[no_mangle]
pub extern "C" fn resvg_image_abs_transform(image: *const usvg::Image) -> resvg_transform {
    if image.is_null() {
        return resvg_transform { a: 1.0, b: 0.0, c: 0.0, d: 1.0, e: 0.0, f: 0.0 };
    }
    let image = unsafe { &*image };
    let t = image.abs_transform();
    resvg_transform { a: t.sx, b: t.ky, c: t.kx, d: t.sy, e: t.tx, f: t.ty }
}

/// Returns true if the image is visible.
#[no_mangle]
pub extern "C" fn resvg_image_is_visible(image: *const usvg::Image) -> bool {
    if image.is_null() {
        return false;
    }
    let image = unsafe { &*image };
    image.is_visible()
}

/// Returns the size of an image.
#[no_mangle]
pub extern "C" fn resvg_image_size(image: *const usvg::Image) -> resvg_size {
    if image.is_null() {
        return resvg_size { width: 0.0, height: 0.0 };
    }
    let image = unsafe { &*image };
    let s = image.size();
    resvg_size { width: s.width(), height: s.height() }
}

/// Returns the kind of an image (JPEG, PNG, GIF, or SVG).
#[no_mangle]
pub extern "C" fn resvg_image_get_kind(image: *const usvg::Image) -> resvg_image_kind {
    if image.is_null() {
        return resvg_image_kind::RESVG_IMAGE_PNG;
    }
    let image = unsafe { &*image };
    match image.kind() {
        usvg::ImageKind::JPEG(_) => resvg_image_kind::RESVG_IMAGE_JPEG,
        usvg::ImageKind::PNG(_) => resvg_image_kind::RESVG_IMAGE_PNG,
        usvg::ImageKind::GIF(_) => resvg_image_kind::RESVG_IMAGE_GIF,
        usvg::ImageKind::SVG(_) => resvg_image_kind::RESVG_IMAGE_SVG,
        usvg::ImageKind::WEBP(_) => resvg_image_kind::RESVG_IMAGE_PNG, // Map WEBP to PNG for now
    }
}

// -----------------------------------------------------------------------------
// Text Node
// -----------------------------------------------------------------------------

/// Returns the ID of a text node.
#[no_mangle]
pub extern "C" fn resvg_text_id(text: *const usvg::Text, len: *mut usize) -> *const std::os::raw::c_char {
    if text.is_null() || len.is_null() {
        return std::ptr::null();
    }
    let text = unsafe { &*text };
    let id = text.id();
    unsafe { *len = id.len(); }
    id.as_ptr() as *const std::os::raw::c_char
}

/// Returns the transform of a text node (same as abs_transform for text).
#[no_mangle]
pub extern "C" fn resvg_text_transform(text: *const usvg::Text) -> resvg_transform {
    if text.is_null() {
        return resvg_transform { a: 1.0, b: 0.0, c: 0.0, d: 1.0, e: 0.0, f: 0.0 };
    }
    let text = unsafe { &*text };
    let t = text.abs_transform();
    resvg_transform { a: t.sx, b: t.ky, c: t.kx, d: t.sy, e: t.tx, f: t.ty }
}

/// Returns the absolute transform of a text node.
#[no_mangle]
pub extern "C" fn resvg_text_abs_transform(text: *const usvg::Text) -> resvg_transform {
    if text.is_null() {
        return resvg_transform { a: 1.0, b: 0.0, c: 0.0, d: 1.0, e: 0.0, f: 0.0 };
    }
    let text = unsafe { &*text };
    let t = text.abs_transform();
    resvg_transform { a: t.sx, b: t.ky, c: t.kx, d: t.sy, e: t.tx, f: t.ty }
}

/// Returns the bounding box of a text node.
#[no_mangle]
pub extern "C" fn resvg_text_bounding_box(text: *const usvg::Text) -> resvg_rect {
    if text.is_null() {
        return resvg_rect { x: 0.0, y: 0.0, width: 0.0, height: 0.0 };
    }
    let text = unsafe { &*text };
    let r = text.bounding_box();
    resvg_rect { x: r.x(), y: r.y(), width: r.width(), height: r.height() }
}

/// Returns the flattened paths of a text node as a group.
/// This provides access to the actual rendered paths after text layout.
#[no_mangle]
pub extern "C" fn resvg_text_flattened(text: *const usvg::Text) -> *const usvg::Group {
    if text.is_null() {
        return std::ptr::null();
    }
    let text = unsafe { &*text };
    text.flattened() as *const usvg::Group
}
'@

$LibRsPath = Join-Path $BuildDir "resvg\crates\c-api\lib.rs"
Add-Content -Path $LibRsPath -Value $RustPatch -Encoding UTF8

Write-Host "Rust patch applied successfully"

#######################################
# Build Windows targets
#######################################

# Set static CRT linkage
$env:RUSTFLAGS = "-C target-feature=+crt-static"

# Create output directories
New-Item -ItemType Directory -Path (Join-Path $BundleDir "windows-x86_64") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $BundleDir "windows-aarch64") -Force | Out-Null

$CApiDir = Join-Path $BuildDir "resvg\crates\c-api"

Write-Host ""
Write-Host "=== Building for x86_64-pc-windows-msvc ==="
Push-Location $CApiDir
cargo build --release --target x86_64-pc-windows-msvc
Pop-Location

$X64Lib = Join-Path $BuildDir "resvg\target\x86_64-pc-windows-msvc\release\resvg.lib"
Copy-Item $X64Lib -Destination (Join-Path $BundleDir "windows-x86_64\libresvg.lib")
Copy-Item $X64Lib -Destination (Join-Path $BundleDir "windows-x86_64\resvg.lib")
Write-Host "x86_64 library: $((Get-Item (Join-Path $BundleDir 'windows-x86_64\libresvg.lib')).Length / 1MB) MB"

Write-Host ""
Write-Host "=== Building for aarch64-pc-windows-msvc ==="
Push-Location $CApiDir
cargo build --release --target aarch64-pc-windows-msvc
Pop-Location

$Arm64Lib = Join-Path $BuildDir "resvg\target\aarch64-pc-windows-msvc\release\resvg.lib"
Copy-Item $Arm64Lib -Destination (Join-Path $BundleDir "windows-aarch64\libresvg.lib")
Copy-Item $Arm64Lib -Destination (Join-Path $BundleDir "windows-aarch64\resvg.lib")
Write-Host "aarch64 library: $((Get-Item (Join-Path $BundleDir 'windows-aarch64\libresvg.lib')).Length / 1MB) MB"

# Clean up build directory
Remove-Item -Recurse -Force $BuildDir

Write-Host ""
Write-Host "=== Done ==="
Write-Host "Windows libraries built successfully:"
Write-Host "  $BundleDir\windows-x86_64\resvg.lib (SPM primary)"
Write-Host "  $BundleDir\windows-x86_64\libresvg.lib (compatibility copy)"
Write-Host "  $BundleDir\windows-aarch64\resvg.lib (SPM primary)"
Write-Host "  $BundleDir\windows-aarch64\libresvg.lib (compatibility copy)"
