function [max_pooled_image] = max_pool(image)
    NUM_TILES = 4; 
    NUM_TILE_PIXELS = 15;
    
    max_pooled_image = zeros(NUM_TILES, NUM_TILES);
    for tile_x = 1:NUM_TILES
        for tile_y = 1:NUM_TILES
            x = 1 + (tile_x-1) * NUM_TILE_PIXELS;
            y = 1 + (tile_y-1) * NUM_TILE_PIXELS;
            max_pooled_image(tile_x, tile_y) = max(max(image(x:x+NUM_TILE_PIXELS-1, y:y+NUM_TILE_PIXELS-1)));
        end
    end
end

