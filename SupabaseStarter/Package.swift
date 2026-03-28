// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SupabaseStarter",
    platforms: [.iOS(.v26)],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.0.0")
    ],
    targets: [
        .executableTarget(
            name: "SupabaseStarter",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift")
            ],
            path: "SupabaseStarter"
        )
    ]
)
