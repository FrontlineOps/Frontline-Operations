if ( isNil "LARs_drawBounds" ) then {
	LARs_drawBounds = [];
	
	//EH to handle draw
	addMissionEventHandler [ "Draw3D", {
		//Draw an objects bounds
		{
			_x params[ "_obj", "_start", "_end", "_color" ];
			if ( player distanceSqr _obj < 200^2 ) then {
				_start = _obj modelToWorld _start;
				_end = _obj modelToWorld _end;
				drawLine3D[ _start, _end, _color ];
			};
		}forEach LARs_drawBounds;
		
	}];
};


params[ "_obj", "_color" ];

_bounds = boundingBoxReal _obj;
_bounds params[ "_mins", "_maxs" ];
_mins params[ "_minX", "_minY", "_minZ" ];
_maxs params[ "_maxX", "_maxY", "_maxZ" ];

{
	_x params[ "_start", "_end" ];
	_nul = LARs_drawBounds pushBack [ _obj, _start, _end, _color ];
}forEach[
	
	[ [ _minX, _minY, _minZ ], [ _minX, _maxY, _minZ ] ],
	[ [ _minX, _maxY, _minZ ], [ _maxX, _maxY, _minZ ] ],
	[ [ _maxX, _maxY, _minZ ], [ _maxX, _minY, _minZ ] ],
	[ [ _maxX, _minY, _minZ ], [ _minX, _minY, _minZ ] ],
	
	[ [ _minX, _minY, _maxZ ], [ _minX, _maxY, _maxZ ] ],
	[ [ _minX, _maxY, _maxZ ], [ _maxX, _maxY, _maxZ ] ],
	[ [ _maxX, _maxY, _maxZ ], [ _maxX, _minY, _maxZ ] ],
	[ [ _maxX, _minY, _maxZ ], [ _minX, _minY, _maxZ ] ],
	
	[ [ _minX, _minY, _minZ ], [ _minX, _minY, _maxZ ] ],
	[ [ _minX, _maxY, _minZ ], [ _minX, _maxY, _maxZ ] ],
	[ [ _maxX, _maxY, _minZ ], [ _maxX, _maxY, _maxZ ] ],
	[ [ _maxX, _minY, _minZ ], [ _maxX, _minY, _maxZ ] ]
];