// Copyright 2021 the Resvg Authors
// SPDX-License-Identifier: Apache-2.0 OR MIT

/**
 * @file resvg.h
 *
 * resvg C API
 */

#ifndef RESVG_H
#define RESVG_H

#include <stdbool.h>
#include <stdint.h>

#define RESVG_MAJOR_VERSION 0
#define RESVG_MINOR_VERSION 45
#define RESVG_PATCH_VERSION 1
#define RESVG_VERSION "0.45.1"

/**
 * @brief List of possible errors.
 */
typedef enum {
    /**
     * Everything is ok.
     */
    RESVG_OK = 0,
    /**
     * Only UTF-8 content are supported.
     */
    RESVG_ERROR_NOT_AN_UTF8_STR,
    /**
     * Failed to open the provided file.
     */
    RESVG_ERROR_FILE_OPEN_FAILED,
    /**
     * Compressed SVG must use the GZip algorithm.
     */
    RESVG_ERROR_MALFORMED_GZIP,
    /**
     * We do not allow SVG with more than 1_000_000 elements for security reasons.
     */
    RESVG_ERROR_ELEMENTS_LIMIT_REACHED,
    /**
     * SVG doesn't have a valid size.
     *
     * Occurs when width and/or height are <= 0.
     *
     * Also occurs if width, height and viewBox are not set.
     */
    RESVG_ERROR_INVALID_SIZE,
    /**
     * Failed to parse an SVG data.
     */
    RESVG_ERROR_PARSING_FAILED,
} resvg_error;

/**
 * @brief A image rendering method.
 */
typedef enum {
    RESVG_IMAGE_RENDERING_OPTIMIZE_QUALITY,
    RESVG_IMAGE_RENDERING_OPTIMIZE_SPEED,
} resvg_image_rendering;

/**
 * @brief A shape rendering method.
 */
typedef enum {
    RESVG_SHAPE_RENDERING_OPTIMIZE_SPEED,
    RESVG_SHAPE_RENDERING_CRISP_EDGES,
    RESVG_SHAPE_RENDERING_GEOMETRIC_PRECISION,
} resvg_shape_rendering;

/**
 * @brief A text rendering method.
 */
typedef enum {
    RESVG_TEXT_RENDERING_OPTIMIZE_SPEED,
    RESVG_TEXT_RENDERING_OPTIMIZE_LEGIBILITY,
    RESVG_TEXT_RENDERING_GEOMETRIC_PRECISION,
} resvg_text_rendering;

/**
 * @brief An SVG to #resvg_render_tree conversion options.
 *
 * Also, contains a fonts database used during text to path conversion.
 * The database is empty by default.
 */
typedef struct resvg_options resvg_options;

/**
 * @brief An opaque pointer to the rendering tree.
 */
typedef struct resvg_render_tree resvg_render_tree;

/**
 * @brief A 2D transform representation.
 */
typedef struct {
    float a;
    float b;
    float c;
    float d;
    float e;
    float f;
} resvg_transform;

/**
 * @brief A size representation.
 */
typedef struct {
    float width;
    float height;
} resvg_size;

/**
 * @brief A rectangle representation.
 */
typedef struct {
    float x;
    float y;
    float width;
    float height;
} resvg_rect;

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Creates an identity transform.
 */
resvg_transform resvg_transform_identity(void);

/**
 * @brief Initializes the library log.
 *
 * Use it if you want to see any warnings.
 *
 * Must be called only once.
 *
 * All warnings will be printed to the `stderr`.
 */
void resvg_init_log(void);

/**
 * @brief Creates a new #resvg_options object.
 *
 * Should be destroyed via #resvg_options_destroy.
 */
resvg_options *resvg_options_create(void);

/**
 * @brief Sets a directory that will be used during relative paths resolving.
 *
 * Expected to be the same as the directory that contains the SVG file,
 * but can be set to any.
 *
 * Must be UTF-8. Can be set to NULL.
 *
 * Default: NULL
 */
void resvg_options_set_resources_dir(resvg_options *opt, const char *path);

/**
 * @brief Sets the target DPI.
 *
 * Impact units conversion.
 *
 * Default: 96
 */
void resvg_options_set_dpi(resvg_options *opt, float dpi);

/**
 * @brief Provides the content of a stylesheet that will be used when resolving CSS attributes.
 *
 * Must be UTF-8. Can be set to NULL.
 *
 * Default: NULL
 */
void resvg_options_set_stylesheet(resvg_options *opt, const char *content);

/**
 * @brief Sets the default font family.
 *
 * Will be used when no `font-family` attribute is set in the SVG.
 *
 * Must be UTF-8. NULL is not allowed.
 *
 * Default: Times New Roman
 */
void resvg_options_set_font_family(resvg_options *opt, const char *family);

/**
 * @brief Sets the default font size.
 *
 * Will be used when no `font-size` attribute is set in the SVG.
 *
 * Default: 12
 */
void resvg_options_set_font_size(resvg_options *opt, float size);

/**
 * @brief Sets the `serif` font family.
 *
 * Must be UTF-8. NULL is not allowed.
 *
 * Has no effect when the `text` feature is not enabled.
 *
 * Default: Times New Roman
 */
void resvg_options_set_serif_family(resvg_options *opt, const char *family);

/**
 * @brief Sets the `sans-serif` font family.
 *
 * Must be UTF-8. NULL is not allowed.
 *
 * Has no effect when the `text` feature is not enabled.
 *
 * Default: Arial
 */
void resvg_options_set_sans_serif_family(resvg_options *opt, const char *family);

/**
 * @brief Sets the `cursive` font family.
 *
 * Must be UTF-8. NULL is not allowed.
 *
 * Has no effect when the `text` feature is not enabled.
 *
 * Default: Comic Sans MS
 */
void resvg_options_set_cursive_family(resvg_options *opt, const char *family);

/**
 * @brief Sets the `fantasy` font family.
 *
 * Must be UTF-8. NULL is not allowed.
 *
 * Has no effect when the `text` feature is not enabled.
 *
 * Default: Papyrus on macOS, Impact on other OS'es
 */
void resvg_options_set_fantasy_family(resvg_options *opt, const char *family);

/**
 * @brief Sets the `monospace` font family.
 *
 * Must be UTF-8. NULL is not allowed.
 *
 * Has no effect when the `text` feature is not enabled.
 *
 * Default: Courier New
 */
void resvg_options_set_monospace_family(resvg_options *opt, const char *family);

/**
 * @brief Sets a comma-separated list of languages.
 *
 * Will be used to resolve a `systemLanguage` conditional attribute.
 *
 * Example: en,en-US.
 *
 * Must be UTF-8. Can be NULL.
 *
 * Default: en
 */
void resvg_options_set_languages(resvg_options *opt, const char *languages);

/**
 * @brief Sets the default shape rendering method.
 *
 * Will be used when an SVG element's `shape-rendering` property is set to `auto`.
 *
 * Default: `RESVG_SHAPE_RENDERING_GEOMETRIC_PRECISION`
 */
void resvg_options_set_shape_rendering_mode(resvg_options *opt, resvg_shape_rendering mode);

/**
 * @brief Sets the default text rendering method.
 *
 * Will be used when an SVG element's `text-rendering` property is set to `auto`.
 *
 * Default: `RESVG_TEXT_RENDERING_OPTIMIZE_LEGIBILITY`
 */
void resvg_options_set_text_rendering_mode(resvg_options *opt, resvg_text_rendering mode);

/**
 * @brief Sets the default image rendering method.
 *
 * Will be used when an SVG element's `image-rendering` property is set to `auto`.
 *
 * Default: `RESVG_IMAGE_RENDERING_OPTIMIZE_QUALITY`
 */
void resvg_options_set_image_rendering_mode(resvg_options *opt, resvg_image_rendering mode);

/**
 * @brief Loads a font data into the internal fonts database.
 *
 * Prints a warning into the log when the data is not a valid TrueType font.
 *
 * Has no effect when the `text` feature is not enabled.
 */
void resvg_options_load_font_data(resvg_options *opt, const char *data, uintptr_t len);

/**
 * @brief Loads a font file into the internal fonts database.
 *
 * Prints a warning into the log when the data is not a valid TrueType font.
 *
 * Has no effect when the `text` feature is not enabled.
 *
 * @return #resvg_error with RESVG_OK, RESVG_ERROR_NOT_AN_UTF8_STR or RESVG_ERROR_FILE_OPEN_FAILED
 */
int32_t resvg_options_load_font_file(resvg_options *opt, const char *file_path);

/**
 * @brief Loads system fonts into the internal fonts database.
 *
 * This method is very IO intensive.
 *
 * This method should be executed only once per #resvg_options.
 *
 * The system scanning is not perfect, so some fonts may be omitted.
 * Please send a bug report in this case.
 *
 * Prints warnings into the log.
 *
 * Has no effect when the `text` feature is not enabled.
 */
void resvg_options_load_system_fonts(resvg_options *opt);

/**
 * @brief Destroys the #resvg_options.
 */
void resvg_options_destroy(resvg_options *opt);

/**
 * @brief Creates #resvg_render_tree from file.
 *
 * .svg and .svgz files are supported.
 *
 * See #resvg_is_image_empty for details.
 *
 * @param file_path UTF-8 file path.
 * @param opt Rendering options. Must not be NULL.
 * @param tree Parsed render tree. Should be destroyed via #resvg_tree_destroy.
 * @return #resvg_error
 */
int32_t resvg_parse_tree_from_file(const char *file_path,
                                   const resvg_options *opt,
                                   resvg_render_tree **tree);

/**
 * @brief Creates #resvg_render_tree from data.
 *
 * See #resvg_is_image_empty for details.
 *
 * @param data SVG data. Can contain SVG string or gzip compressed data. Must not be NULL.
 * @param len Data length.
 * @param opt Rendering options. Must not be NULL.
 * @param tree Parsed render tree. Should be destroyed via #resvg_tree_destroy.
 * @return #resvg_error
 */
int32_t resvg_parse_tree_from_data(const char *data,
                                   uintptr_t len,
                                   const resvg_options *opt,
                                   resvg_render_tree **tree);

/**
 * @brief Checks that tree has any nodes.
 *
 * @param tree Render tree.
 * @return Returns `true` if tree has no nodes.
 */
bool resvg_is_image_empty(const resvg_render_tree *tree);

/**
 * @brief Returns an image size.
 *
 * The size of an image that is required to render this SVG.
 *
 * Note that elements outside the viewbox will be clipped. This is by design.
 * If you want to render the whole SVG content, use #resvg_get_image_bbox instead.
 *
 * @param tree Render tree.
 * @return Image size.
 */
resvg_size resvg_get_image_size(const resvg_render_tree *tree);

/**
 * @brief Returns an object bounding box.
 *
 * This bounding box does not include objects stroke and filter regions.
 * This is what SVG calls "absolute object bonding box".
 *
 * If you're looking for a "complete" bounding box see #resvg_get_image_bbox
 *
 * @param tree Render tree.
 * @param bbox Image's object bounding box.
 * @return `false` if an image has no elements.
 */
bool resvg_get_object_bbox(const resvg_render_tree *tree, resvg_rect *bbox);

/**
 * @brief Returns an image bounding box.
 *
 * This bounding box contains the maximum SVG dimensions.
 * It's size can be bigger or smaller than #resvg_get_image_size
 * Use it when you want to avoid clipping of elements that are outside the SVG viewbox.
 *
 * @param tree Render tree.
 * @param bbox Image's bounding box.
 * @return `false` if an image has no elements.
 */
bool resvg_get_image_bbox(const resvg_render_tree *tree, resvg_rect *bbox);

/**
 * @brief Returns `true` if a renderable node with such an ID exists.
 *
 * @param tree Render tree.
 * @param id Node's ID. UTF-8 string. Must not be NULL.
 * @return `true` if a node exists.
 * @return `false` if a node doesn't exist or ID isn't a UTF-8 string.
 * @return `false` if a node exists, but not renderable.
 */
bool resvg_node_exists(const resvg_render_tree *tree, const char *id);

/**
 * @brief Returns node's transform by ID.
 *
 * @param tree Render tree.
 * @param id Node's ID. UTF-8 string. Must not be NULL.
 * @param transform Node's transform.
 * @return `true` if a node exists.
 * @return `false` if a node doesn't exist or ID isn't a UTF-8 string.
 * @return `false` if a node exists, but not renderable.
 */
bool resvg_get_node_transform(const resvg_render_tree *tree,
                              const char *id,
                              resvg_transform *transform);

/**
 * @brief Returns node's bounding box in canvas coordinates by ID.
 *
 * @param tree Render tree.
 * @param id Node's ID. Must not be NULL.
 * @param bbox Node's bounding box.
 * @return `false` if a node with such an ID does not exist
 * @return `false` if ID isn't a UTF-8 string.
 * @return `false` if ID is an empty string
 */
bool resvg_get_node_bbox(const resvg_render_tree *tree, const char *id, resvg_rect *bbox);

/**
 * @brief Returns node's bounding box, including stroke, in canvas coordinates by ID.
 *
 * @param tree Render tree.
 * @param id Node's ID. Must not be NULL.
 * @param bbox Node's bounding box.
 * @return `false` if a node with such an ID does not exist
 * @return `false` if ID isn't a UTF-8 string.
 * @return `false` if ID is an empty string
 */
bool resvg_get_node_stroke_bbox(const resvg_render_tree *tree, const char *id, resvg_rect *bbox);

/**
 * @brief Destroys the #resvg_render_tree.
 */
void resvg_tree_destroy(resvg_render_tree *tree);

/**
 * @brief Renders the #resvg_render_tree onto the pixmap.
 *
 * @param tree A render tree.
 * @param transform A root SVG transform. Can be used to position SVG inside the `pixmap`.
 * @param width Pixmap width.
 * @param height Pixmap height.
 * @param pixmap Pixmap data. Should have width*height*4 size and contain
 *               premultiplied RGBA8888 pixels.
 */
void resvg_render(const resvg_render_tree *tree,
                  resvg_transform transform,
                  uint32_t width,
                  uint32_t height,
                  char *pixmap);

/**
 * @brief Renders a Node by ID onto the image.
 *
 * @param tree A render tree.
 * @param id Node's ID. Must not be NULL.
 * @param transform A root SVG transform. Can be used to position SVG inside the `pixmap`.
 * @param width Pixmap width.
 * @param height Pixmap height.
 * @param pixmap Pixmap data. Should have width*height*4 size and contain
 *               premultiplied RGBA8888 pixels.
 * @return `false` when `id` is not a non-empty UTF-8 string.
 * @return `false` when the selected `id` is not present.
 * @return `false` when an element has a zero bbox.
 */
bool resvg_render_node(const resvg_render_tree *tree,
                       const char *id,
                       resvg_transform transform,
                       uint32_t width,
                       uint32_t height,
                       char *pixmap);



/**
 * @brief Exports the parsed tree back to normalized SVG string.
 *
 * The SVG is normalized by usvg with all defaults applied:
 * - Missing fill defaults to black
 * - CSS styles are resolved
 * - `<use>` references are expanded
 * - clip-path elements are resolved
 *
 * @param tree Render tree.
 * @param len Output: length of the returned string (excluding null terminator).
 * @return Normalized SVG string. NULL on error. Must be freed via resvg_svg_string_destroy.
 */
char* resvg_tree_to_svg(const resvg_render_tree *tree, uintptr_t *len);

/**
 * @brief Frees SVG string allocated by resvg_tree_to_svg.
 */
void resvg_svg_string_destroy(char *svg);

// =============================================================================
// Tree Traversal API
// =============================================================================

// -----------------------------------------------------------------------------
// Type Definitions
// -----------------------------------------------------------------------------

/** Node type enumeration */
typedef enum {
    RESVG_NODE_GROUP = 0,
    RESVG_NODE_PATH = 1,
    RESVG_NODE_IMAGE = 2,
    RESVG_NODE_TEXT = 3,
} resvg_node_type;

/** Mask type enumeration */
typedef enum {
    RESVG_MASK_LUMINANCE = 0,
    RESVG_MASK_ALPHA = 1,
} resvg_mask_type;

/** Paint type enumeration */
typedef enum {
    RESVG_PAINT_COLOR = 0,
    RESVG_PAINT_LINEAR_GRADIENT = 1,
    RESVG_PAINT_RADIAL_GRADIENT = 2,
    RESVG_PAINT_PATTERN = 3,
} resvg_paint_type;

/** Fill rule enumeration */
typedef enum {
    RESVG_FILL_NONZERO = 0,
    RESVG_FILL_EVENODD = 1,
} resvg_fill_rule;

/** Line cap enumeration */
typedef enum {
    RESVG_LINECAP_BUTT = 0,
    RESVG_LINECAP_ROUND = 1,
    RESVG_LINECAP_SQUARE = 2,
} resvg_linecap;

/** Line join enumeration */
typedef enum {
    RESVG_LINEJOIN_MITER = 0,
    RESVG_LINEJOIN_ROUND = 1,
    RESVG_LINEJOIN_BEVEL = 2,
    RESVG_LINEJOIN_MITER_CLIP = 3,
} resvg_linejoin;

/** Path segment type enumeration */
typedef enum {
    RESVG_PATH_SEG_MOVE_TO = 0,
    RESVG_PATH_SEG_LINE_TO = 1,
    RESVG_PATH_SEG_QUAD_TO = 2,
    RESVG_PATH_SEG_CUBIC_TO = 3,
    RESVG_PATH_SEG_CLOSE = 4,
} resvg_path_segment_type;

/** Blend mode enumeration */
typedef enum {
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
} resvg_blend_mode;

/** Spread method enumeration */
typedef enum {
    RESVG_SPREAD_PAD = 0,
    RESVG_SPREAD_REFLECT = 1,
    RESVG_SPREAD_REPEAT = 2,
} resvg_spread_method;

/** Image kind enumeration */
typedef enum {
    RESVG_IMAGE_JPEG = 0,
    RESVG_IMAGE_PNG = 1,
    RESVG_IMAGE_GIF = 2,
    RESVG_IMAGE_SVG = 3,
} resvg_image_kind;

/** RGBA color */
typedef struct {
    uint8_t r;
    uint8_t g;
    uint8_t b;
    uint8_t a;
} resvg_color;

/** Gradient stop */
typedef struct {
    float offset;
    uint8_t r;
    uint8_t g;
    uint8_t b;
    uint8_t a;
} resvg_gradient_stop;

/** Path segment */
typedef struct {
    resvg_path_segment_type seg_type;
    float x;
    float y;
    float x1;
    float y1;
    float x2;
    float y2;
} resvg_path_segment;

/** Opaque group pointer (borrow from tree, do NOT free) */
typedef struct resvg_group resvg_group;

/** Opaque node pointer (borrow from tree, do NOT free) */
typedef struct resvg_node resvg_node;

/** Opaque path pointer (borrow from tree, do NOT free) */
typedef struct resvg_path resvg_path;

/** Opaque image pointer (borrow from tree, do NOT free) */
typedef struct resvg_image resvg_image;

/** Opaque text pointer (borrow from tree, do NOT free) */
typedef struct resvg_text resvg_text;

/** Opaque mask pointer (borrow from tree, do NOT free) */
typedef struct resvg_mask resvg_mask;

/** Opaque clip path pointer (borrow from tree, do NOT free) */
typedef struct resvg_clip_path resvg_clip_path;

/** Opaque fill pointer (borrow from tree, do NOT free) */
typedef struct resvg_fill resvg_fill;

/** Opaque stroke pointer (borrow from tree, do NOT free) */
typedef struct resvg_stroke resvg_stroke;

/** Opaque linear gradient pointer (borrow from tree, do NOT free) */
typedef struct resvg_linear_gradient resvg_linear_gradient;

/** Opaque radial gradient pointer (borrow from tree, do NOT free) */
typedef struct resvg_radial_gradient resvg_radial_gradient;

// -----------------------------------------------------------------------------
// Core Tree Traversal
// -----------------------------------------------------------------------------

/** Returns the root group of the render tree. Valid as long as tree is alive. */
const resvg_group* resvg_tree_root(const resvg_render_tree *tree);

/** Returns the number of children in a group. */
uintptr_t resvg_group_children_count(const resvg_group *group);

/** Returns a child node at the given index. NULL if out of bounds. */
const resvg_node* resvg_group_child_at(const resvg_group *group, uintptr_t index);

/** Returns the type of a node. */
resvg_node_type resvg_node_get_type(const resvg_node *node);

/** Casts a node to a group. Returns NULL if not a group. */
const resvg_group* resvg_node_as_group(const resvg_node *node);

/** Casts a node to a path. Returns NULL if not a path. */
const resvg_path* resvg_node_as_path(const resvg_node *node);

/** Casts a node to an image. Returns NULL if not an image. */
const resvg_image* resvg_node_as_image(const resvg_node *node);

/** Casts a node to text. Returns NULL if not text. */
const resvg_text* resvg_node_as_text(const resvg_node *node);

// -----------------------------------------------------------------------------
// Group Properties
// -----------------------------------------------------------------------------

/** Returns the ID of a group. Length stored in len. */
const char* resvg_group_id(const resvg_group *group, uintptr_t *len);

/** Returns the relative transform of a group. */
resvg_transform resvg_group_transform(const resvg_group *group);

/** Returns the absolute transform of a group. */
resvg_transform resvg_group_abs_transform(const resvg_group *group);

/** Returns the opacity of a group. */
float resvg_group_opacity(const resvg_group *group);

/** Returns the blend mode of a group. */
resvg_blend_mode resvg_group_blend_mode(const resvg_group *group);

/** Returns true if the group has a mask. */
bool resvg_group_has_mask(const resvg_group *group);

/** Returns true if the group has a clip path. */
bool resvg_group_has_clip_path(const resvg_group *group);

/** Returns true if the group is isolated. */
bool resvg_group_isolate(const resvg_group *group);

// -----------------------------------------------------------------------------
// Mask Access
// -----------------------------------------------------------------------------

/** Returns the mask of a group. NULL if no mask. */
const resvg_mask* resvg_group_mask(const resvg_group *group);

/** Returns the ID of a mask. */
const char* resvg_mask_id(const resvg_mask *mask, uintptr_t *len);

/** Returns the bounding rect of a mask. */
resvg_rect resvg_mask_rect(const resvg_mask *mask);

/** Returns the type of a mask (luminance or alpha). */
resvg_mask_type resvg_mask_kind(const resvg_mask *mask);

/** Returns the root group of a mask's content. */
const resvg_group* resvg_mask_root(const resvg_mask *mask);

/** Returns the nested mask. NULL if none. */
const resvg_mask* resvg_mask_mask(const resvg_mask *mask);

// -----------------------------------------------------------------------------
// Clip Path Access
// -----------------------------------------------------------------------------

/** Returns the clip path of a group. NULL if no clip path. */
const resvg_clip_path* resvg_group_clip_path(const resvg_group *group);

/** Returns the ID of a clip path. */
const char* resvg_clip_path_id(const resvg_clip_path *clip, uintptr_t *len);

/** Returns the transform of a clip path. */
resvg_transform resvg_clip_path_transform(const resvg_clip_path *clip);

/** Returns the root group of a clip path's content. */
const resvg_group* resvg_clip_path_root(const resvg_clip_path *clip);

// -----------------------------------------------------------------------------
// Path Properties
// -----------------------------------------------------------------------------

/** Returns the ID of a path. */
const char* resvg_path_id(const resvg_path *path, uintptr_t *len);

/** Returns the relative transform of a path. */
resvg_transform resvg_path_transform(const resvg_path *path);

/** Returns the absolute transform of a path. */
resvg_transform resvg_path_abs_transform(const resvg_path *path);

/** Returns true if the path is visible. */
bool resvg_path_is_visible(const resvg_path *path);

/** Returns the number of segments in a path's data. */
uintptr_t resvg_path_data_len(const resvg_path *path);

/** Returns a path segment at the given index. Returns false if out of bounds. */
bool resvg_path_data_segment(const resvg_path *path, uintptr_t index, resvg_path_segment *segment);

/** Returns true if the path has a fill. */
bool resvg_path_has_fill(const resvg_path *path);

/** Returns true if the path has a stroke. */
bool resvg_path_has_stroke(const resvg_path *path);

/** Returns the fill of a path. NULL if no fill. */
const resvg_fill* resvg_path_fill(const resvg_path *path);

/** Returns the stroke of a path. NULL if no stroke. */
const resvg_stroke* resvg_path_stroke(const resvg_path *path);

// -----------------------------------------------------------------------------
// Fill Properties
// -----------------------------------------------------------------------------

/** Returns the paint type of a fill. */
resvg_paint_type resvg_fill_paint_type(const resvg_fill *fill);

/** Returns the color of a fill (if solid). */
resvg_color resvg_fill_color(const resvg_fill *fill);

/** Returns the opacity of a fill. */
float resvg_fill_opacity(const resvg_fill *fill);

/** Returns the fill rule. */
resvg_fill_rule resvg_fill_get_rule(const resvg_fill *fill);

/** Returns the linear gradient. NULL if not a linear gradient. */
const resvg_linear_gradient* resvg_fill_linear_gradient(const resvg_fill *fill);

/** Returns the radial gradient. NULL if not a radial gradient. */
const resvg_radial_gradient* resvg_fill_radial_gradient(const resvg_fill *fill);

// -----------------------------------------------------------------------------
// Stroke Properties
// -----------------------------------------------------------------------------

/** Returns the paint type of a stroke. */
resvg_paint_type resvg_stroke_paint_type(const resvg_stroke *stroke);

/** Returns the color of a stroke (if solid). */
resvg_color resvg_stroke_color(const resvg_stroke *stroke);

/** Returns the opacity of a stroke. */
float resvg_stroke_opacity(const resvg_stroke *stroke);

/** Returns the width of a stroke. */
float resvg_stroke_width(const resvg_stroke *stroke);

/** Returns the line cap of a stroke. */
resvg_linecap resvg_stroke_linecap(const resvg_stroke *stroke);

/** Returns the line join of a stroke. */
resvg_linejoin resvg_stroke_linejoin(const resvg_stroke *stroke);

/** Returns the miter limit of a stroke. */
float resvg_stroke_miter_limit(const resvg_stroke *stroke);

/** Returns the number of dash values. */
uintptr_t resvg_stroke_dasharray_len(const resvg_stroke *stroke);

/** Returns a dash value at the given index. */
float resvg_stroke_dasharray_at(const resvg_stroke *stroke, uintptr_t index);

/** Returns the dash offset of a stroke. */
float resvg_stroke_dashoffset(const resvg_stroke *stroke);

/** Returns the linear gradient. NULL if not a linear gradient. */
const resvg_linear_gradient* resvg_stroke_linear_gradient(const resvg_stroke *stroke);

/** Returns the radial gradient. NULL if not a radial gradient. */
const resvg_radial_gradient* resvg_stroke_radial_gradient(const resvg_stroke *stroke);

// -----------------------------------------------------------------------------
// Linear Gradient
// -----------------------------------------------------------------------------

/** Returns the ID of a linear gradient. */
const char* resvg_linear_gradient_id(const resvg_linear_gradient *lg, uintptr_t *len);

/** Returns the x1 coordinate. */
float resvg_linear_gradient_x1(const resvg_linear_gradient *lg);

/** Returns the y1 coordinate. */
float resvg_linear_gradient_y1(const resvg_linear_gradient *lg);

/** Returns the x2 coordinate. */
float resvg_linear_gradient_x2(const resvg_linear_gradient *lg);

/** Returns the y2 coordinate. */
float resvg_linear_gradient_y2(const resvg_linear_gradient *lg);

/** Returns the transform of a linear gradient. */
resvg_transform resvg_linear_gradient_transform(const resvg_linear_gradient *lg);

/** Returns the spread method. */
resvg_spread_method resvg_linear_gradient_spread_method(const resvg_linear_gradient *lg);

/** Returns the number of stops. */
uintptr_t resvg_linear_gradient_stops_count(const resvg_linear_gradient *lg);

/** Returns a stop at the given index. Returns false if out of bounds. */
bool resvg_linear_gradient_stop_at(const resvg_linear_gradient *lg, uintptr_t index, resvg_gradient_stop *stop);

// -----------------------------------------------------------------------------
// Radial Gradient
// -----------------------------------------------------------------------------

/** Returns the ID of a radial gradient. */
const char* resvg_radial_gradient_id(const resvg_radial_gradient *rg, uintptr_t *len);

/** Returns the cx coordinate. */
float resvg_radial_gradient_cx(const resvg_radial_gradient *rg);

/** Returns the cy coordinate. */
float resvg_radial_gradient_cy(const resvg_radial_gradient *rg);

/** Returns the radius. */
float resvg_radial_gradient_r(const resvg_radial_gradient *rg);

/** Returns the fx coordinate. */
float resvg_radial_gradient_fx(const resvg_radial_gradient *rg);

/** Returns the fy coordinate. */
float resvg_radial_gradient_fy(const resvg_radial_gradient *rg);

/** Returns the transform of a radial gradient. */
resvg_transform resvg_radial_gradient_transform(const resvg_radial_gradient *rg);

/** Returns the spread method. */
resvg_spread_method resvg_radial_gradient_spread_method(const resvg_radial_gradient *rg);

/** Returns the number of stops. */
uintptr_t resvg_radial_gradient_stops_count(const resvg_radial_gradient *rg);

/** Returns a stop at the given index. Returns false if out of bounds. */
bool resvg_radial_gradient_stop_at(const resvg_radial_gradient *rg, uintptr_t index, resvg_gradient_stop *stop);

// -----------------------------------------------------------------------------
// Image Node
// -----------------------------------------------------------------------------

/** Returns the ID of an image. */
const char* resvg_image_id(const resvg_image *image, uintptr_t *len);

/** Returns the transform of an image. */
resvg_transform resvg_image_transform(const resvg_image *image);

/** Returns the absolute transform of an image. */
resvg_transform resvg_image_abs_transform(const resvg_image *image);

/** Returns true if the image is visible. */
bool resvg_image_is_visible(const resvg_image *image);

/** Returns the size of an image. */
resvg_size resvg_image_size(const resvg_image *image);

/** Returns the kind of an image (JPEG, PNG, GIF, or SVG). */
resvg_image_kind resvg_image_get_kind(const resvg_image *image);

// -----------------------------------------------------------------------------
// Text Node
// -----------------------------------------------------------------------------

/** Returns the ID of a text node. */
const char* resvg_text_id(const resvg_text *text, uintptr_t *len);

/** Returns the transform of a text node. */
resvg_transform resvg_text_transform(const resvg_text *text);

/** Returns the absolute transform of a text node. */
resvg_transform resvg_text_abs_transform(const resvg_text *text);

/** Returns the bounding box of a text node. */
resvg_rect resvg_text_bounding_box(const resvg_text *text);

/** Returns the flattened paths of a text node as a group. */
const resvg_group* resvg_text_flattened(const resvg_text *text);


#ifdef __cplusplus
} // extern "C"
#endif

#endif /* RESVG_H */
