import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import Snapshot from "./Snapshot.cdc"
import Base64Util from "./Base64Util.cdc"

// The `SnapshotViewer` contract is a sample implementation of the `IViewer` struct interface.
//
pub contract SnapshotViewer {

    pub struct BasicHTMLViewer: Snapshot.IViewer {

        pub fun getView(snap: &Snapshot.Snap): AnyStruct {
            var html = "<!DOCTYPE html>\n"
            html = html.concat("<html lang=\"ja\">\n")
            html = html.concat("<head>\n")
            html = html.concat("<meta charset=\"UTF-8\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n")
            html = html.concat("<style>\n")
            html = html.concat("body, html { margin: 0; padding: 0; width: 100%; height: 100%; }\n")
            html = html.concat("canvas { border: 1px solid black; display: block; width: 100%; height: 100%; }\n")
            html = html.concat("#popup { display: none; position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%); background-color: white; padding: 20px; border: 0; box-shadow: 0 0 8px gray; font-size: 0.8em; }\n")
            html = html.concat("</style>\n")
            html = html.concat("</head>\n")
            html = html.concat("<body>\n")
            html = html.concat("<canvas id=\"viewerCanvas\"></canvas>\n")
            html = html.concat("<div id=\"popup\"></div>\n")
            html = html.concat("<script>\n")
            html = html.concat("const canvas = document.getElementById(\"viewerCanvas\");\n")
            html = html.concat("const ctx = canvas.getContext(\"2d\");\n")
            html = html.concat("const popup = document.getElementById(\"popup\");\n")
            html = html.concat("let isAnimating = true;\n")
            html = html.concat("\n")
            html = html.concat("function resizeCanvas() {\n")
            html = html.concat("    canvas.width = window.innerWidth;\n")
            html = html.concat("    canvas.height = window.innerHeight;\n")
            html = html.concat("}\n")
            html = html.concat("\n")
            html = html.concat("function escapeHtml(unsafe) {\n")
            html = html.concat("    return String(unsafe).replace(/&/g, \"&amp;\").replace(/</g, \"&lt;\").replace(/>/g, \"&gt;\").replace(/\"/g, \"&quot;\");\n")
            html = html.concat("}\n")
            html = html.concat("\n")
            html = html.concat("function decodeBase64(base64) {\n")
            html = html.concat("    try {\n")
            html = html.concat("        const binary = atob(base64);\n")
            html = html.concat("        let bytes = new Uint8Array(binary.length);\n")
            html = html.concat("        for (let i = 0; i < binary.length; i++) {\n")
            html = html.concat("            bytes[i] = binary.charCodeAt(i);\n")
            html = html.concat("        }\n")
            html = html.concat("        return new TextDecoder().decode(bytes);\n")
            html = html.concat("    } catch (e) {\n")
            html = html.concat("        console.error(e);\n")
            html = html.concat("        return \"\";\n")
            html = html.concat("    }\n")
            html = html.concat("}\n")
            html = html.concat("\n")
            html = html.concat("window.addEventListener(\"resize\", resizeCanvas);\n")
            html = html.concat("resizeCanvas();\n")
            html = html.concat("\n")

            html = html.concat("const ownerAddress = \"").concat(snap.ownerAddress.toString()).concat("\"\n")
            html = html.concat("const snapshotTime = Number((").concat(snap.time.toString()).concat(" | 0) * 1000)\n")

            html = html.concat("const data = [\n")

            for collectionPublicPath in snap.ownedNFTs.keys {
                let nftsInfo = snap.ownedNFTs[collectionPublicPath]!
                for id in nftsInfo.keys {
                    let metadata = nftsInfo[id]!.metadata
                    let name = metadata?.name ?? nftsInfo[id]!.nftID.toString()
                    let collectionPublicPath = nftsInfo[id]!.collectionPublicPath
                    let nftType = nftsInfo[id]!.nftType.identifier
                    let thumbnail = metadata?.thumbnail?.uri() ?? ""
                    html = html.concat("    {\n")
                    html = html.concat("        nftID: ").concat(nftsInfo[id]!.nftID.toString()).concat(",\n")
                    html = html.concat("        name: decodeBase64(\"").concat(Base64Util.encode(name)).concat("\"),\n")
                    html = html.concat("        collectionPublicPath: \"").concat(collectionPublicPath).concat("\",\n")
                    html = html.concat("        nftType: \"").concat(nftType).concat("\",\n")
                    html = html.concat("        thumbnail: decodeBase64(\"").concat(Base64Util.encode(thumbnail)).concat("\").replace(\"ipfs://\", \"https://dweb.link/ipfs/\"),\n")
                    html = html.concat("    },\n")
                }
            }

            html = html.concat("];\n")
            html = html.concat("\n")
            html = html.concat("data.map(info => {\n")
            html = html.concat("    const angle = Math.random() * 2 * Math.PI;\n")
            html = html.concat("    info.x = Math.random() * canvas.width;\n")
            html = html.concat("    info.y = Math.random() * canvas.height;\n")
            html = html.concat("    info.dx = Math.cos(angle) * 0.2;\n")
            html = html.concat("    info.dy = Math.sin(angle) * 0.2;\n")
            html = html.concat("    info.width = canvas.width * 0.08,\n")
            html = html.concat("    info.height = null,\n")
            html = html.concat("    info.image = null\n")
            html = html.concat("});\n")
            html = html.concat("\n")
            html = html.concat("let loadedImages = 0;\n")
            html = html.concat("\n")
            html = html.concat("data.forEach(item => {\n")
            html = html.concat("    const img = new Image();\n")
            html = html.concat("    img.onload = function() {\n")
            html = html.concat("        loadedImages++;\n")
            html = html.concat("        item.image = img;\n")
            html = html.concat("        item.height = img.height * (item.width / img.width);\n")
            html = html.concat("        if (loadedImages === data.length) {\n")
            html = html.concat("            requestAnimationFrame(draw);\n")
            html = html.concat("        }\n")
            html = html.concat("    }\n")
            html = html.concat("    img.onerror = function() {\n")
            html = html.concat("        loadedImages++;\n")
            html = html.concat("        if (loadedImages === data.length) {\n")
            html = html.concat("            requestAnimationFrame(draw);\n")
            html = html.concat("        }\n")
            html = html.concat("    }\n")
            html = html.concat("    img.src = item.thumbnail;\n")
            html = html.concat("});\n")
            html = html.concat("\n")
            html = html.concat("canvas.addEventListener(\"click\", function(event) {\n")
            html = html.concat("    const rect = canvas.getBoundingClientRect();\n")
            html = html.concat("    const x = event.clientX - rect.left;\n")
            html = html.concat("    const y = event.clientY - rect.top;\n")
            html = html.concat("\n")
            html = html.concat("    let clickedItem = null;\n")
            html = html.concat("    for (const item of data) {\n")
            html = html.concat("        if (x > item.x - item.width/2 && x < item.x + item.width/2 &&\n")
            html = html.concat("            y > item.y - item.height/2 && y < item.y + item.height/2) {\n")
            html = html.concat("            clickedItem = item;\n")
            html = html.concat("            break;\n")
            html = html.concat("        }\n")
            html = html.concat("    }\n")
            html = html.concat("\n")
            html = html.concat("    if (clickedItem) {\n")
            html = html.concat("        isAnimating = false;\n")
            html = html.concat("        let imageHtml = \"\";\n")
            html = html.concat("        if (clickedItem.image) {\n")
            html = html.concat("            imageHtml = `<img src=\"${clickedItem.thumbnail}\" width=\"${clickedItem.width * 3}\" height=\"${clickedItem.height * 3}\" style=\"display:block; margin:auto;\">`;\n")
            html = html.concat("        }\n")
            html = html.concat("        popup.innerHTML = imageHtml +\n")
            html = html.concat("                        \"<p>Name: \" + escapeHtml(clickedItem.name) + \"</p>\" + \n")
            html = html.concat("                        \"<p>PublicPath: \" + clickedItem.collectionPublicPath + \"</p>\" +\n")
            html = html.concat("                        \"<p>Type: \" + escapeHtml(clickedItem.nftType) + \"</p>\" +\n")
            html = html.concat("                        \"<p>ID: \" + clickedItem.nftID + \"</p>\" +\n")
            html = html.concat("                        \"<p>Owner: \" + ownerAddress + \"</p>\" +\n")
            html = html.concat("                        \"<p>Time: \" + new Date(snapshotTime).toLocaleString() + \"</p>\";\n")
            html = html.concat("        popup.style.display = \"block\";\n")
            html = html.concat("    } else {\n")
            html = html.concat("        isAnimating = true;\n")
            html = html.concat("        popup.style.display = \"none\";\n")
            html = html.concat("        requestAnimationFrame(draw);\n")
            html = html.concat("    }\n")
            html = html.concat("});\n")
            html = html.concat("\n")
            html = html.concat("function draw() {\n")
            html = html.concat("    if (!isAnimating) return;\n")
            html = html.concat("\n")
            html = html.concat("    ctx.clearRect(0, 0, canvas.width, canvas.height);\n")
            html = html.concat("\n")
            html = html.concat("    data.forEach(item => {\n")
            html = html.concat("        item.x += item.dx;\n")
            html = html.concat("        item.y += item.dy;\n")
            html = html.concat("\n")
            html = html.concat("        if (item.x - item.width/2 > canvas.width) item.x = -item.width/2;\n")
            html = html.concat("        if (item.x + item.width/2 < 0) item.x = canvas.width + item.width/2;\n")
            html = html.concat("        if (item.y - item.height/2 > canvas.height) item.y = -item.height/2;\n")
            html = html.concat("        if (item.y + item.height/2 < 0) item.y = canvas.height + item.height/2;\n")
            html = html.concat("\n")
            html = html.concat("        if (item.image) {\n")
            html = html.concat("            ctx.drawImage(item.image, 0, 0, item.image.width, item.image.height, item.x - item.width/2, item.y - item.height/2, item.width, item.height);\n")
            html = html.concat("        } else {\n")
            html = html.concat("            item.height = item.width;\n")
            html = html.concat("            ctx.fillStyle = \"#ddd\";\n")
            html = html.concat("            ctx.fillRect(item.x - item.width/2, item.y - item.height/2, item.width, item.height);\n")
            html = html.concat("\n")
            html = html.concat("            ctx.fillStyle = \"#999\";\n")
            html = html.concat("            ctx.textAlign = \"center\";\n")
            html = html.concat("            ctx.textBaseline = \"middle\";\n")
            html = html.concat("            ctx.fillText(\"NFT\", item.x, item.y);\n")
            html = html.concat("        }\n")
            html = html.concat("\n")
            html = html.concat("        ctx.fillStyle = \"black\";\n")
            html = html.concat("        ctx.textAlign = \"center\";\n")
            html = html.concat("        ctx.textBaseline = \"alphabetic\";\n")
            html = html.concat("        ctx.fillText(item.name, item.x, item.y + item.height/2 + 15);\n")
            html = html.concat("    });\n")
            html = html.concat("\n")
            html = html.concat("    requestAnimationFrame(draw);\n")
            html = html.concat("}\n")
            html = html.concat("</script>\n")
            html = html.concat("</body>\n")
            html = html.concat("</html>")

            return html
        }
    }
}
