-- ============================================================================
-- Master Data Population Script
-- Insert core reference data (colors and subject elements)
-- ============================================================================

-- Colors data with hex codes
INSERT INTO colors (color_name, color_hex) VALUES
('Alizarin Crimson', '#4E1500'),
('Black Gesso', '#000000'),
('Bright Red', '#DB0000'),
('Burnt Umber', '#8A3324'),
('Cadmium Yellow', '#FFEC00'),
('Dark Sienna', '#5F2E1F'),
('Indian Red', '#CD5C5C'),
('Indian Yellow', '#FFB800'),
('Liquid Black', '#000000'),
('Liquid Clear', NULL),
('Midnight Black', '#000000'),
('Phthalo Blue', '#0C0040'),
('Phthalo Green', '#102E3C'),
('Prussian Blue', '#021E44'),
('Sap Green', '#0A3410'),
('Titanium White', '#FFFFFF'),
('Van Dyke Brown', '#221B15'),
('Yellow Ochre', '#C79B00');

-- Subject elements data with categories
INSERT INTO subject_elements (element_name, element_category) VALUES
-- Frame Types
('APPLE_FRAME', 'FRAME'),
('CIRCLE_FRAME', 'FRAME'),
('DOUBLE_OVAL_FRAME', 'FRAME'),
('FLORIDA_FRAME', 'FRAME'),
('FRAMED', 'FRAME'),
('HALF_CIRCLE_FRAME', 'FRAME'),
('HALF_OVAL_FRAME', 'FRAME'),
('OVAL_FRAME', 'FRAME'),
('RECTANGLE_3D_FRAME', 'FRAME'),
('RECTANGULAR_FRAME', 'FRAME'),
('SEASHELL_FRAME', 'FRAME'),
('SPLIT_FRAME', 'FRAME'),
('TOMB_FRAME', 'FRAME'),
('TRIPLE_FRAME', 'FRAME'),
('WINDOW_FRAME', 'FRAME'),
('WOOD_FRAMED', 'FRAME'),

-- Weather and Sky Elements
('AURORA_BOREALIS', 'WEATHER'),
('CIRRUS', 'WEATHER'),
('CLOUDS', 'WEATHER'),
('CUMULUS', 'WEATHER'),
('FOG', 'WEATHER'),
('MOON', 'WEATHER'),
('NIGHT', 'WEATHER'),
('SNOW', 'WEATHER'),
('SUN', 'WEATHER'),
('WINTER', 'WEATHER'),

-- Landscape Features
('BEACH', 'LANDSCAPE'),
('CLIFF', 'LANDSCAPE'),
('HILLS', 'LANDSCAPE'),
('LAKE', 'LANDSCAPE'),
('LAKES', 'LANDSCAPE'),
('MOUNTAIN', 'LANDSCAPE'),
('MOUNTAINS', 'LANDSCAPE'),
('OCEAN', 'LANDSCAPE'),
('PATH', 'LANDSCAPE'),
('RIVER', 'LANDSCAPE'),
('ROCKS', 'LANDSCAPE'),
('SNOWY_MOUNTAIN', 'LANDSCAPE'),
('WATERFALL', 'LANDSCAPE'),
('WAVES', 'LANDSCAPE'),

-- Vegetation
('BUSHES', 'VEGETATION'),
('CACTUS', 'VEGETATION'),
('CONIFER', 'VEGETATION'),
('DECIDUOUS', 'VEGETATION'),
('FLOWERS', 'VEGETATION'),
('GRASS', 'VEGETATION'),
('PALM_TREES', 'VEGETATION'),
('TREE', 'VEGETATION'),
('TREES', 'VEGETATION'),

-- Structures
('BARN', 'STRUCTURE'),
('BOAT', 'STRUCTURE'),
('BRIDGE', 'STRUCTURE'),
('BUILDING', 'STRUCTURE'),
('CABIN', 'STRUCTURE'),
('DOCK', 'STRUCTURE'),
('FARM', 'STRUCTURE'),
('FENCE', 'STRUCTURE'),
('LIGHTHOUSE', 'STRUCTURE'),
('MILL', 'STRUCTURE'),
('STRUCTURE', 'STRUCTURE'),
('WINDMILL', 'STRUCTURE'),

-- Special Elements
('FIRE', 'WEATHER'),
('GUEST', 'SPECIAL'),
('PERSON', 'SPECIAL'),
('PORTRAIT', 'SPECIAL'),

-- Special Guests (as recorded in data)
('DIANE_ANDRE', 'GUEST'),
('STEVE_ROSS', 'GUEST');

-- Verification queries
SELECT 'Colors loaded:' as status, COUNT(*) as count FROM colors;
SELECT 'Subject elements loaded:' as status, COUNT(*) as count FROM subject_elements;
SELECT element_category, COUNT(*) as count 
FROM subject_elements 
GROUP BY element_category 
ORDER BY element_category;

COMMIT;
