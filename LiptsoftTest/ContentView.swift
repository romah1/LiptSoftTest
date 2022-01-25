
import SwiftUI

struct ContentView: View {
    var body: some View {
        CatTable()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

class CatTableDataModel: ObservableObject {
    @Published var catsData: [Cat?]
    private let api: TheCatApi
    private let pageSize: Int
    init() {
        self.api = TheCatApi()
        self.catsData = []
        self.pageSize = 100
        fetchInitialCats()
    }
    
    private func fetchCats(page: Int, limit: Int, completionHandler: @escaping (Data?, URLResponse?) -> Void) {
        self.api.makeGetCatsRequest(page: page, limit: limit) { (data, response, error) in
            guard error == nil else {
                return
            }
            completionHandler(data, response)
        }
    }
    
    private func fetchCatsPage(page: Int) {
        for _ in 0..<self.pageSize {
            self.catsData.append(nil)
        }
        fetchCats(page: page, limit: self.pageSize) { (data, _) in
            guard let data = data else {
                return
            }
            let decodedCats = try? JSONDecoder().decode([Cat].self, from: data)
            if let decodedCats = decodedCats {
                DispatchQueue.main.async {
                    for i in 0..<decodedCats.count {
                        self.catsData[page * self.pageSize + i] = decodedCats[i]
                    }
                }
            }
        }
    }
    
    private func fetchInitialCats() {
        fetchCatsPage(page: 0)
    }
    
    func fetchMoreCats(idx: Int) {
        guard idx % self.pageSize == 0 else {
            return
        }
        let page = idx / self.pageSize + 1
        if page * self.pageSize == self.catsData.count {
            fetchCatsPage(page: page)
        }
        
    }
}

struct CatTable: View {
    @StateObject var catTableDataModel: CatTableDataModel
    @State var isPresented = false
    init() {
        self._catTableDataModel = StateObject(wrappedValue: CatTableDataModel())
    }
    var body: some View {
        List(0 ..< self.catTableDataModel.catsData.count, id: \.self) { idx in
            if let cat = self.catTableDataModel.catsData[idx] {
                CatTableCellView(cat: cat)
                    .frame(height: 60)
                    .onAppear {
                        self.catTableDataModel.fetchMoreCats(idx: idx)
                    }
            } else {
                CatTableCellViewPlaceholder()
                    .frame(height: 60)
            }
        }
    }
}

struct CatTableCellViewPlaceholder: View {
    var body: some View {
        HStack {
            Spacer()
            ProgressView()
            Spacer()
        }
    }
}

struct CatTableCellView: View {
    @State var isPresented = false
    @StateObject var imageModel: ImageModel
    let cat: Cat
    
    init(cat: Cat) {
        self.cat = cat
        self._imageModel = StateObject(wrappedValue: ImageModel(urlStr: cat.url))
    }
        
    var body: some View {
        HStack(spacing: 16) {
            if let image = self.imageModel.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 50)
            } else {
                ProgressView()
                    .frame(width: CGFloat(cat.width) * 50 / CGFloat(cat.height), height: 50)
            }
            
            HStack {
                Spacer()
                Text("\(self.cat.width) x \(self.cat.height)")
                Spacer()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            self.isPresented = true
        }
        .sheet(isPresented: self.$isPresented, onDismiss: {self.isPresented = false}
        ) {
            GeometryReader { geometry in
                VStack {
                    Spacer()
                        .frame(height: 50)
                    if let image = self.imageModel.image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: geometry.size.width * 0.8, maxHeight: geometry.size.height * 0.4)
                    } else {
                        ProgressView()
                            .frame(maxWidth: geometry.size.width * 0.8, maxHeight: geometry.size.height * 0.4)
                    }
                    Spacer()
                    Text(
                        self.cat.jsonStringRepresentation()
                    )
                    Spacer()
                }.frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
    }
}

class ImageModel: ObservableObject {
    @Published var image: UIImage?
    let imageCache: ImageCache
    let urlStr: String
    
    init(urlStr: String) {
        self.urlStr = urlStr
        self.imageCache = ImageCache.defaultCache
        self.loadImage()
    }
    
    func loadImage() {
        if !loadImageFromCache() {
            loadImageFromUrl()
        }
    }
    
    func loadImageFromCache() -> Bool {
        guard let cachedImage = self.imageCache.get(forKey: self.urlStr) else {
            return false
        }
        
        self.image = cachedImage
        return true
    }
    
    func loadImageFromUrl() {
        let url = URL(string: self.urlStr)
        guard let url = url else {
            return
        }
        let task = URLSession.shared.dataTask(
            with: url,
            completionHandler: handleLoadImageCompletion(data:response:error:)
        )
        task.resume()
    }
    
    func handleLoadImageCompletion(data: Data?, response: URLResponse?, error: Error?) {
        guard error == nil else {
            return
        }
        guard let data = data else {
            return
        }
        DispatchQueue.main.async {
            guard let image = UIImage(data: data) else {
                return
            }
            self.image = image
            self.imageCache.set(forKey: self.urlStr, image: image)
        }
    }
}

class ImageCache {
    let cache = NSCache<NSString, UIImage>()
    
    func set(forKey: String, image: UIImage) {
        cache.setObject(image, forKey: NSString(string: forKey))
    }
    
    func get(forKey: String) -> UIImage? {
        return cache.object(forKey: NSString(string: forKey))
    }
    
    static let defaultCache = ImageCache()
}
