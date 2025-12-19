import Foundation
import Testing

@testable import Resvg

@Suite("SvgRasterizer Tests")
struct SvgRasterizerTests {
    let rasterizer = SvgRasterizer()

    @Test("Rasterizes simple SVG")
    func rasterizeSimpleSvg() throws {
        let svg = """
            <svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">
                <rect width="100" height="100" fill="red"/>
            </svg>
            """
        let result = try rasterizer.rasterize(data: Data(svg.utf8))

        #expect(result.width == 100)
        #expect(result.height == 100)
        #expect(result.rgba.count == 100 * 100 * 4)
    }

    @Test("Applies scale factor")
    func applyScaleFactor() throws {
        let svg = """
            <svg width="50" height="50" xmlns="http://www.w3.org/2000/svg">
                <circle cx="25" cy="25" r="25" fill="blue"/>
            </svg>
            """
        let result = try rasterizer.rasterize(data: Data(svg.utf8), scale: 2.0)

        #expect(result.width == 100)
        #expect(result.height == 100)
    }

    @Test("Throws on invalid SVG")
    func throwsOnInvalidSvg() throws {
        let invalidData = Data("not an svg".utf8)

        #expect(throws: ResvgError.self) {
            try rasterizer.rasterize(data: invalidData)
        }
    }

    @Test("Throws on empty SVG")
    func throwsOnEmptySvg() throws {
        let emptySvg = """
            <svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">
            </svg>
            """

        #expect(throws: ResvgError.emptyImage) {
            try rasterizer.rasterize(data: Data(emptySvg.utf8))
        }
    }

    @Test("Rasterizes from file")
    func rasterizeFromFile() throws {
        let bundle = Bundle.module
        guard let url = bundle.url(forResource: "test", withExtension: "svg", subdirectory: "Fixtures") else {
            Issue.record("Test fixture not found")
            return
        }

        let result = try rasterizer.rasterize(file: url)
        #expect(result.width > 0)
        #expect(result.height > 0)
    }
}
